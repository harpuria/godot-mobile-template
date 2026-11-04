// ONE store IAP SDK v21(21.04.00)을 Godot 4.7 Android plugin v2로 노출한다.
// GodotGooglePlayBilling 3.3.0과 같은 메서드·신호·Dictionary 키를 제공해 템플릿의
// AndroidBillingAdapter 흐름(수신 → 게임 검증 → consume/acknowledge)을 그대로 쓴다.
// 상태: 소스·로컬 컴파일 검사만 수행했다. 실기기·ONE store 결제 검증 전에는 Unverified다.
package com.mobiletemplate.onestore;

import android.app.Activity;

import com.gaa.sdk.auth.GaaSignInClient;
import com.gaa.sdk.iap.AcknowledgeParams;
import com.gaa.sdk.iap.ConsumeParams;
import com.gaa.sdk.iap.IapResult;
import com.gaa.sdk.iap.ProductDetail;
import com.gaa.sdk.iap.ProductDetailsParams;
import com.gaa.sdk.iap.PurchaseClient;
import com.gaa.sdk.iap.PurchaseClientStateListener;
import com.gaa.sdk.iap.PurchaseData;
import com.gaa.sdk.iap.PurchaseFlowParams;

import org.godotengine.godot.Dictionary;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

public class GodotOneStoreIap extends GodotPlugin {
	// Google Billing 계약의 purchase_state 값. ONE store에는 pending 상태가 없다.
	private static final int GOOGLE_STATE_UNSPECIFIED = 0;
	private static final int GOOGLE_STATE_PURCHASED = 1;

	private PurchaseClient client;
	private String publicKey = "";
	// consume/acknowledge는 PurchaseData 객체가 필요하므로 token으로 보관한다.
	private final Map<String, PurchaseData> purchases = new ConcurrentHashMap<>();

	public GodotOneStoreIap(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return "GodotOneStoreIap";
	}

	@Override
	public Set<SignalInfo> getPluginSignals() {
		return new HashSet<>(Arrays.asList(
				new SignalInfo("connected"),
				new SignalInfo("disconnected"),
				new SignalInfo("connect_error", Integer.class, String.class),
				new SignalInfo("query_product_details_response", Dictionary.class),
				new SignalInfo("query_purchases_response", Dictionary.class),
				new SignalInfo("on_purchase_updated", Dictionary.class),
				new SignalInfo("consume_purchase_response", Dictionary.class),
				new SignalInfo("acknowledge_purchase_response", Dictionary.class)));
	}

	/** ONE store 개발자 센터의 라이선스 공개 키. initPlugin 전에 호출한다. */
	@UsedByGodot
	public void setPublicKey(String key) {
		publicKey = key == null ? "" : key;
	}

	@UsedByGodot
	public void initPlugin() {
		if (client != null) {
			return;
		}
		PurchaseClient.Builder builder = PurchaseClient.newBuilder(getActivity())
				.setListener((result, list) -> emitSignal("on_purchase_updated", purchasesResponse(result, list)));
		if (!publicKey.isEmpty()) {
			builder.setBase64PublicKey(publicKey);
		}
		client = builder.build();
	}

	@UsedByGodot
	public void startConnection() {
		if (client == null) {
			emitSignal("connect_error", PurchaseClient.ResponseCode.ERROR_CLIENT_NOT_ENABLED, "initPlugin required");
			return;
		}
		client.startConnection(new PurchaseClientStateListener() {
			@Override
			public void onSetupFinished(IapResult result) {
				if (result.isSuccess()) {
					emitSignal("connected");
				} else {
					recover(result.getResponseCode(), false);
					emitSignal("connect_error", result.getResponseCode(), String.valueOf(result.getMessage()));
				}
			}

			@Override
			public void onServiceDisconnected() {
				emitSignal("disconnected");
			}
		});
	}

	@UsedByGodot
	public void endConnection() {
		if (client != null) {
			client.endConnection();
		}
	}

	@UsedByGodot
	public boolean isReady() {
		return client != null && client.isReady();
	}

	/** Google 계약의 "inapp"/"subs"를 ONE store 상품 타입으로 바꿔 조회한다. */
	@UsedByGodot
	public void queryProductDetails(String[] productIds, String type) {
		ProductDetailsParams params = ProductDetailsParams.newBuilder()
				.setProductIdList(Arrays.asList(productIds))
				.setProductType(storeType(type))
				.build();
		client.queryProductDetailsAsync(params, (result, details) -> {
			Dictionary response = result(result);
			List<Object> items = new ArrayList<>();
			if (details != null) {
				for (ProductDetail detail : details) {
					items.add(productDetail(detail, "subs".equals(type)));
				}
			}
			response.put("product_details", items.toArray());
			emitSignal("query_product_details_response", response);
		});
	}

	@UsedByGodot
	public void queryPurchases(String type, boolean includeSuspended) {
		client.queryPurchasesAsync(storeType(type),
				(result, list) -> emitSignal("query_purchases_response", purchasesResponse(result, list)));
	}

	/** 일회성 상품 구매. ONE store에는 purchase option/offer가 없어 빈 값만 받는다. */
	@UsedByGodot
	public Dictionary purchase(String productId, String optionId, String offerId, boolean personalized) {
		return launch(productId, PurchaseClient.ProductType.INAPP);
	}

	@UsedByGodot
	public Dictionary purchaseSubscription(String productId, String basePlanId, String offerId, boolean personalized) {
		return launch(productId, PurchaseClient.ProductType.SUBS);
	}

	@UsedByGodot
	public void consumePurchase(String token) {
		PurchaseData data = purchases.get(token);
		if (data == null) {
			emitSignal("consume_purchase_response", tokenResponse(PurchaseClient.ResponseCode.RESULT_ITEM_NOT_OWNED, token));
			return;
		}
		client.consumeAsync(ConsumeParams.newBuilder().setPurchaseData(data).build(), (result, consumed) -> {
			if (result.isSuccess()) {
				purchases.remove(token);
			}
			emitSignal("consume_purchase_response", tokenResponse(result.getResponseCode(), token));
		});
	}

	@UsedByGodot
	public void acknowledgePurchase(String token) {
		PurchaseData data = purchases.get(token);
		if (data == null) {
			emitSignal("acknowledge_purchase_response", tokenResponse(PurchaseClient.ResponseCode.RESULT_ITEM_NOT_OWNED, token));
			return;
		}
		client.acknowledgeAsync(AcknowledgeParams.newBuilder().setPurchaseData(data).build(),
				(result, acknowledged) -> emitSignal("acknowledge_purchase_response", tokenResponse(result.getResponseCode(), token)));
	}

	private Dictionary launch(String productId, String type) {
		Activity activity = getActivity();
		if (client == null || activity == null) {
			return codeResponse(PurchaseClient.ResponseCode.ERROR_CLIENT_NOT_ENABLED);
		}
		PurchaseFlowParams params = PurchaseFlowParams.newBuilder()
				.setProductId(productId)
				.setProductType(type)
				.setQuantity(1)
				.build();
		IapResult result = client.launchPurchaseFlow(activity, params);
		recover(result.getResponseCode(), true);
		return result(result);
	}

	/**
	 * 로그인·업데이트가 필요하면 ONE store 화면을 띄운다. 결과 코드는 그대로 게임에 전달한다.
	 * 사용자가 누른 구매(interactive)만 로그인 화면을 열고, 배경 조회는 저장된 로그인만 시도한다.
	 */
	private void recover(int code, boolean interactive) {
		Activity activity = getActivity();
		if (activity == null) {
			return;
		}
		GaaSignInClient signIn = GaaSignInClient.getClient(activity);
		if (code == PurchaseClient.ResponseCode.RESULT_NEED_LOGIN) {
			if (interactive) {
				activity.runOnUiThread(() -> signIn.launchSignInFlow(activity, ignored -> { }));
			} else {
				activity.runOnUiThread(() -> signIn.silentSignIn(ignored -> { }));
			}
		} else if (code == PurchaseClient.ResponseCode.RESULT_NEED_UPDATE && interactive) {
			activity.runOnUiThread(() -> signIn.launchUpdateOrInstallFlow(activity, (resultCode, message) -> { }));
		}
	}

	private static String storeType(String type) {
		return "subs".equals(type) ? PurchaseClient.ProductType.SUBS : PurchaseClient.ProductType.INAPP;
	}

	private Dictionary purchasesResponse(IapResult result, List<PurchaseData> list) {
		recover(result.getResponseCode(), false);
		Dictionary response = result(result);
		List<Object> items = new ArrayList<>();
		if (list != null) {
			for (PurchaseData data : list) {
				purchases.put(data.getPurchaseToken(), data);
				items.add(purchase(data));
			}
		}
		response.put("purchases", items.toArray());
		return response;
	}

	private static Dictionary purchase(PurchaseData data) {
		Dictionary item = new Dictionary();
		item.put("product_ids", new String[] { data.getProductId() });
		item.put("purchase_token", data.getPurchaseToken());
		// CANCEL/REFUND는 템플릿 계약상 지급 대상이 아니므로 UNSPECIFIED로 보낸다.
		item.put("purchase_state", data.getPurchaseState() == PurchaseData.PurchaseState.PURCHASED ? GOOGLE_STATE_PURCHASED : GOOGLE_STATE_UNSPECIFIED);
		item.put("onestore_purchase_state", data.getPurchaseState());
		item.put("is_acknowledged", data.isAcknowledged());
		item.put("is_suspended", false);
		item.put("order_id", data.getOrderId());
		item.put("package_name", data.getPackageName());
		item.put("purchase_time", data.getPurchaseTime());
		item.put("quantity", data.getQuantity());
		item.put("signature", data.getSignature());
		item.put("original_json", data.getOriginalJson());
		return item;
	}

	/** Google 3.3.0의 offer 목록 모양으로 맞춘다. 후보가 하나라 어댑터가 자동 선택한다. */
	private static Dictionary productDetail(ProductDetail detail, boolean subscription) {
		Dictionary offer = new Dictionary();
		offer.put(subscription ? "base_plan_id" : "purchase_option_id", "");
		offer.put("offer_id", null);
		offer.put("formatted_price", detail.getPrice());
		offer.put("price_amount_micros", detail.getPriceAmountMicros());
		offer.put("price_currency_code", detail.getPriceCurrencyCode());
		if (subscription) {
			offer.put("billing_period", detail.getSubscriptionPeriodUnitCode());
			offer.put("free_trial_period", detail.getFreeTrialPeriod());
		}
		Dictionary item = new Dictionary();
		item.put("product_id", detail.getProductId());
		item.put("name", detail.getTitle());
		item.put("title", detail.getTitle());
		item.put("product_type", subscription ? "subs" : "inapp");
		item.put(subscription ? "subscription_offer_details" : "one_time_purchase_offer_details_list", new Object[] { offer });
		return item;
	}

	private static Dictionary result(IapResult result) {
		Dictionary response = codeResponse(result.getResponseCode());
		response.put("debug_message", String.valueOf(result.getMessage()));
		return response;
	}

	private static Dictionary codeResponse(int code) {
		Dictionary response = new Dictionary();
		response.put("response_code", code);
		return response;
	}

	private static Dictionary tokenResponse(int code, String token) {
		Dictionary response = codeResponse(code);
		response.put("token", token);
		return response;
	}
}
