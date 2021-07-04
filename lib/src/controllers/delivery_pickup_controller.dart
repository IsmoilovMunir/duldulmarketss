import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../models/address.dart' as model;
import '../models/payment_method.dart';
import '../repository/settings_repository.dart' as settingRepo;
import '../repository/user_repository.dart' as userRepo;
import 'cart_controller.dart';
import '../models/cart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../helpers/maps_util.dart';

class DeliveryPickupController extends CartController {
  GlobalKey<ScaffoldState> scaffoldKey;
  model.Address deliveryAddress;
  PaymentMethodList list;
  bool canDelivery;
  double deliveryFeeCalculate;

  DeliveryPickupController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    super.listenForCarts();
    listenForDeliveryAddress();

    print(settingRepo.deliveryAddress.value.toMap());
  }

  void listenForDeliveryAddress() async {
    this.deliveryAddress = settingRepo.deliveryAddress.value;
  }

  void addAddress(model.Address address) {
    userRepo.addAddress(address).then((value) {
      setState(() {
        settingRepo.deliveryAddress.value = value;
        this.deliveryAddress = value;
      });
    }).whenComplete(() {
      ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
        content: Text(S.of(state.context).new_address_added_successfully),
      ));
    });
  }

  void updateAddress(model.Address address) {
    userRepo.updateAddress(address).then((value) {
      setState(() {
        settingRepo.deliveryAddress.value = value;
        this.deliveryAddress = value;
      });
    }).whenComplete(() {
      ScaffoldMessenger.of(scaffoldKey?.currentContext).showSnackBar(SnackBar(
        content: Text(S.of(state.context).the_address_updated_successfully),
      ));
    });
  }

  PaymentMethod getPickUpMethod() {
    return list.pickupList.elementAt(0);
  }

  PaymentMethod getDeliveryMethod() {
    return list.pickupList.elementAt(1);
  }

  void toggleDelivery() {
    list.pickupList.forEach((element) {
      if (element != getDeliveryMethod()) {
        element.selected = false;
      }
    });
    setState(() {
      getDeliveryMethod().selected = !getDeliveryMethod().selected;
    });
  }

  void togglePickUp() {
    list.pickupList.forEach((element) {
      if (element != getPickUpMethod()) {
        element.selected = false;
      }
    });
    setState(() {
      getPickUpMethod().selected = !getPickUpMethod().selected;
    });
  }

  PaymentMethod getSelectedMethod() {
    return list.pickupList.firstWhere((element) => element.selected);
  }

  @override
  void goCheckout(BuildContext context) {
    Navigator.of(state.context).pushNamed(getSelectedMethod().route);
  }

  void calculateDeliveryFeeNew(List<Cart> carts, String distance) async {
    var dis = double.parse(distance);
    print(dis);
    if (dis <= carts[0].product.market.deliveryRange) {
      toggleDelivery();
      if (dis >= 6 && getDeliveryMethod().selected) {
        //settingRepo.setting.value.deliveryFrom + 1
        var km = dis.toInt() - 5; //settingRepo.setting.value.deliveryFrom
        deliveryFeeCalculate =
            (km * 10).toDouble(); // settingRepo.setting.value.Amount_for_km
        calculateDeliveryFee(deliveryCalculate: deliveryFeeCalculate);
      } else
        calculateDeliveryFee();
    }
  }
}
