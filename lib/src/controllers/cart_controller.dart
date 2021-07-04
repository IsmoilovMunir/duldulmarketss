import 'package:flutter/material.dart';
import 'package:markets/src/models/route_argument.dart';
import 'package:markets/src/models/setting.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../generated/l10n.dart';
import '../helpers/helper.dart';
import '../helpers/maps_util.dart';
import '../models/cart.dart';
import '../models/coupon.dart';
import '../models/address.dart';
import '../repository/cart_repository.dart';
import '../repository/coupon_repository.dart';
import '../repository/settings_repository.dart' as settingsRepo;
import '../repository/user_repository.dart';

class CartController extends ControllerMVC {
  List<Cart> carts = <Cart>[];
  double taxAmount = 0.0;
  double deliveryFee = 0.0;
  int cartCount = 0;
  double subTotal = 0.0;
  double total = 0.0;
  double minimum_orden = settingsRepo.setting.value.minimum_orden;
  double free_delivery = settingsRepo.setting.value.free_delivery;
  double lat1 = 0.0;
  double long1 = 0.0;
  double lat2 = 0.0;
  double long2 = 0.0;
  double distanceResponse = 0.0;
  double distance;
  GlobalKey<ScaffoldState> scaffoldKey;

  CartController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
  }

  void listenForCarts({String message}) async {
    carts.clear();
    final Stream<Cart> stream = await getCart();
    stream.listen((Cart _cart) {
      if (!carts.contains(_cart)) {
        setState(() {
          settingsRepo.coupon = _cart.product.applyCoupon(settingsRepo.coupon);
          carts.add(_cart);
        });
      }
    }, onError: (a) {
      print(a);
      ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
        content: Text(S.of(state.context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if (carts.isNotEmpty) {
        calculateSubtotal();
      }
      if (message != null) {
        ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
      onLoadingCartDone();
    });
  }

  void onLoadingCartDone() {}

  void listenForCartsCount({String message}) async {
    final Stream<int> stream = await getCartCount();
    stream.listen((int _count) {
      setState(() {
        this.cartCount = _count;
      });
    }, onError: (a) {
      print(a);
      ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
        content: Text(S.of(state.context).verify_your_internet_connection),
      ));
    });
  }

  Future<void> refreshCarts() async {
    setState(() {
      carts = [];
    });
    listenForCarts(message: S.of(state.context).carts_refreshed_successfuly);
  }

  void removeFromCart(Cart _cart) async {
    setState(() {
      this.carts.remove(_cart);
    });
    removeCart(_cart).then((value) {
      calculateSubtotal();
      ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
        content: Text(S
            .of(state.context)
            .the_product_was_removed_from_your_cart(_cart.product.name)),
      ));
    });
  }

  void calculateSubtotal() async {
    double cartPrice = 0;
    subTotal = 0;
    carts.forEach((cart) {
      cartPrice = cart.product.price;
      cart.options.forEach((element) {
        cartPrice += element.price;
      });
      cartPrice *= cart.quantity;
      subTotal += cartPrice;
    });
    calculateDeliveryFee();
    setState(() {});
  }

  void calculateDeliveryFee({double deliveryCalculate}) async {
    //if (Helper.canDelivery(carts[0].product.market)){
    deliveryFee = carts[0].product.market.deliveryFee;

    if (subTotal >= free_delivery) {
      deliveryFee = 0;
    } else {
      if (deliveryCalculate != null) {
        deliveryFee += deliveryCalculate;
      }
    }

    //}
    calculateTaxAmount();
    setState(() {});
  }

  void calculateTaxAmount() async {
    taxAmount =
        (subTotal + deliveryFee) * carts[0].product.market.defaultTax / 100;
    calculateTotal();
    setState(() {});
  }

  void calculateTotal() async {
    total = subTotal + taxAmount + deliveryFee;
    setState(() {});
  }

  void doApplyCoupon(String code, {String message}) async {
    settingsRepo.coupon = new Coupon.fromJSON({"code": code, "valid": null});
    final Stream<Coupon> stream = await verifyCoupon(code);
    stream.listen((Coupon _coupon) async {
      settingsRepo.coupon = _coupon;
    }, onError: (a) {
      print(a);
      ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
        content: Text(S.of(state.context).verify_your_internet_connection),
      ));
    }, onDone: () {
      listenForCarts();
    });
  }

  incrementQuantity(Cart cart) {
    if (cart.quantity <= 99) {
      ++cart.quantity;
      updateCart(cart);
      calculateSubtotal();
    }
  }

  decrementQuantity(Cart cart) {
    if (cart.quantity > 1) {
      --cart.quantity;
      updateCart(cart);
      calculateSubtotal();
    }
  }

  void goCheckout(BuildContext context) {
    if (!currentUser.value.profileCompleted()) {
      ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
        content: Text(S.of(state.context).completeYourProfileDetailsToContinue),
        action: SnackBarAction(
          label: S.of(state.context).settings,
          textColor: Theme.of(state.context).accentColor,
          onPressed: () {
            Navigator.of(state.context).pushNamed('/Settings');
          },
        ),
      ));
    } else {
      if (carts[0].product.market.closed) {
        ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
          content: Text(S.of(state.context).this_market_is_closed_),
        ));
      } else {
        if (total >= minimum_orden) {
          getDistance().then((value) => Navigator.of(state.context).pushNamed(
              '/DeliveryPickup',
              arguments: new RouteArgument(
                  param: value, heroTag: distance.toString())));
        } else {
          ScaffoldMessenger.of(scaffoldKey?.currentContext)
              .showSnackBar(SnackBar(
            content: Text(
                "Your order must be greater than or equal to $minimum_orden rubles."),
          ));
        }
      }
    }
  }

  Color getCouponIconColor() {
    if (settingsRepo.coupon?.valid == true) {
      return Colors.green;
    } else if (settingsRepo.coupon?.valid == false) {
      return Colors.redAccent;
    }
    return Theme.of(state.context).focusColor.withOpacity(0.7);
  }

  Future<bool> getDistance() async {
    MapsUtil mapsUtil = new MapsUtil();
    //     //Coordenadas Cliente
    lat1 = settingsRepo.deliveryAddress.value
        ?.latitude; //19.139219; //19.625472; //currentAddress.latitude;
    long1 = settingsRepo.deliveryAddress.value
        ?.longitude; //-98.964251; //-99.045490; //currentAddress.longitude;
    //     //Coordenadas Tienda
    lat2 = double.parse(carts[0].product.market.latitude);
    long2 = double.parse(carts[0].product.market.longitude);
    try {
      distanceResponse = await mapsUtil.getDistanceByGoogleService(
          new LatLng(lat2, long2),
          new LatLng(lat1, long1),
          settingsRepo.setting.value.googleMapsKey);
    } catch (e) {
      return false;
    }
    distance = distanceResponse / 1000; //Distance
    if (distance <= carts[0].product.market.deliveryRange)
      return true;
    else
      return false;
  }
}
