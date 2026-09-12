import 'package:flutter/material.dart';

import '../helper/session.dart';
import '../screns/works/widgets/unreviewed_chip.dart';
import '../screns/user/user_contact.dart';
import 'app_drawer.dart';
import 'app_router.dart';
import 'app_section.dart';
import 'logout_confirm.dart';

/// Бургер кабинета, собранный из состояния приложения.
///
/// Экраны подрядчика держат каждый свой `Scaffold` и открывают drawer через
/// общий `GlobalKey` (`myOpenDrawer`), поэтому бургер нужен в каждом из них
/// — как раньше стояли `MyDrawer()` и `DrawerForeman()`. Этот виджет без
/// параметров: раздел берёт у [appRouter], роль и имя — из сессии. Значит,
/// и экрану, открытому `Navigator.push` поверх оболочки, достаётся живой
/// бургер, а не копия с чужой подсветкой.
class ShellDrawer extends StatelessWidget {
  const ShellDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appRouter,
      builder: (BuildContext context, _) {
        final int roleId = idUserTest;
        final String? userName =
            userProfile.isEmpty ? null : userProfile[0]['name']?.toString();
        return AppDrawer(
          current: appRouter.section,
          roleId: roleId,
          userName: userName,
          onSelect: (AppSection section) {
            // В узком окне бургер выезжает поверх экрана — после выбора
            // его надо убрать; в широком он стоит колонкой, убирать нечего.
            final ScaffoldState? scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) scaffold.closeDrawer();
            appRouter.goTo(section);
          },
          onLogout: () async {
            if (await confirmLogout(context)) await signOut();
          },
          // Число непросмотренных — на «Работах» у обеих ролей. Первое
          // значение кладёт оболочка при входе, дальше — лента.
          trailing: const <AppSection, Widget>{
            AppSection.works: UnreviewedChip(),
          },
        );
      },
    );
  }
}
