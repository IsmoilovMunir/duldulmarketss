import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:intl/intl.dart';

import '../../generated/l10n.dart';
import '../controllers/delivery_pickup_controller.dart';
import '../elements/CartBottomDetailsWidget.dart';
import '../elements/DeliveryAddressDialog.dart';
import '../elements/DeliveryAddressesItemWidget.dart';
import '../elements/NotDeliverableAddressesItemWidget.dart';
import '../elements/PickUpMethodItemWidget.dart';
import '../elements/ShoppingCartButtonWidget.dart';
import '../helpers/helper.dart';
import '../models/address.dart';
import '../models/payment_method.dart';
import '../models/route_argument.dart';

class DeliveryPickupWidget extends StatefulWidget {
  final RouteArgument routeArgument;

  DeliveryPickupWidget({Key key, this.routeArgument}) : super(key: key);

  @override
  _DeliveryPickupWidgetState createState() => _DeliveryPickupWidgetState();
}

class _DeliveryPickupWidgetState extends StateMVC<DeliveryPickupWidget> {
  DeliveryPickupController _con;
  String dateDelivery = '';
  String timeDelivery = '';

  _DeliveryPickupWidgetState() : super(DeliveryPickupController()) {
    _con = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (_con.list == null) {
      _con.list = new PaymentMethodList(context);
//      widget.pickup = widget.list.pickupList.elementAt(0);
//      widget.delivery = widget.list.pickupList.elementAt(1);
    }
    return Scaffold(
      key: _con.scaffoldKey,
      bottomNavigationBar: CartBottomDetailsWidget(con: _con),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          S.of(context).delivery_or_pickup,
          style: Theme.of(context)
              .textTheme
              .headline6
              .merge(TextStyle(letterSpacing: 1.3)),
        ),
        actions: <Widget>[
          new ShoppingCartButtonWidget(
              iconColor: Theme.of(context).hintColor,
              labelColor: Theme.of(context).accentColor),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 10),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                leading: Icon(
                  Icons.domain,
                  color: Theme.of(context).hintColor,
                ),
                title: Text(
                  S.of(context).pickup,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headline4,
                ),
                subtitle: Text(
                  S.of(context).pickup_your_product_from_the_market,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
            ),
            PickUpMethodItem(
                paymentMethod: _con.getPickUpMethod(),
                onPressed: (paymentMethod) {
                  _con.togglePickUp();
                }),
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20, bottom: 10, left: 20, right: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    leading: Icon(
                      Icons.map_outlined,
                      color: Theme.of(context).hintColor,
                    ),
                    title: Text(
                      S.of(context).delivery,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    subtitle: _con.carts.isNotEmpty &&
                            Helper.canDelivery(_con.carts[0].product.market,
                                carts: _con.carts)
                        ? Text(
                            S
                                .of(context)
                                .click_to_confirm_your_address_and_pay_or_long_press,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.caption,
                          )
                        : Text(
                            S.of(context).deliveryMethodNotAllowed,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.caption,
                          ),
                  ),
                ),
                _con.carts.isNotEmpty &&
                        widget.routeArgument.param &&
                        Helper.canDelivery(_con.carts[0].product.market,
                            carts: _con.carts)
                    ? Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 20, bottom: 10, left: 20, right: 10),
                            child: GestureDetector(
                              onTap: () {
                                showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2030))
                                    .then((value) {
                                  print(value);
                                  if (value != null) {
                                    _con.dateDelivery =
                                        DateFormat('dd-MM-yyyy').format(value);
                                    dateDelivery =
                                        DateFormat('dd-MM-yyyy').format(value);
                                    showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                        builder: (context, child) {
                                          return MediaQuery(
                                            data: MediaQuery.of(context)
                                                .copyWith(
                                                    alwaysUse24HourFormat:
                                                        true),
                                            child: child,
                                          );
                                        }).then((value) {
                                      _con.timeDelivery = value.format(context);
                                      timeDelivery = value.format(context);
                                    });
                                  }
                                });
                                // print('$result');
                              },
                              child: ListTile(
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 0),
                                leading: Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).hintColor,
                                ),
                                title: Text(
                                  'Click to select delivery date',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.headline4,
                                ),
                                subtitle: Text(
                                  'Delivery date: ' +
                                      dateDelivery +
                                      ' ' +
                                      timeDelivery,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .merge(TextStyle(fontSize: 16)),
                                ),
                              ),
                            ),
                          ),
                          DeliveryAddressesItemWidget(
                            paymentMethod: _con.getDeliveryMethod(),
                            address: _con.deliveryAddress,
                            onPressed: (Address _address) {
                              if (_con.deliveryAddress.id == null ||
                                  _con.deliveryAddress.id == 'null') {
                                DeliveryAddressDialog(
                                  context: context,
                                  address: _address,
                                  onChanged: (Address _address) {
                                    _con.addAddress(_address);
                                  },
                                );
                              } else {
                                _con.calculateDeliveryFeeNew(
                                    _con.carts, widget.routeArgument.heroTag);
                              }
                            },
                            onLongPress: (Address _address) {
                              DeliveryAddressDialog(
                                context: context,
                                address: _address,
                                onChanged: (Address _address) {
                                  _con.updateAddress(_address);
                                },
                              );
                            },
                          )
                        ],
                      )
                    : NotDeliverableAddressesItemWidget()
              ],
            )
          ],
        ),
      ),
    );
  }
}
