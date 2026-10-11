import 'package:flutter/material.dart';
import '../app.dart';
import '../core/sync.dart';
import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: sync, builder: (_, __) => sync.user == null ? const _Login() : const _Profile());
}

class _Login extends StatefulWidget {
  const _Login();
  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final em = TextEditingController(), pw = TextEditingController();
  bool create = false, busy = false, hidden = true;
  String err = '';
  bool okMsg = false;

  Future<void> go() async {
    final e = em.text.trim(), p = pw.text;
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(e)) { setState(() { err = 'أدخل بريدًا إلكترونيًا صحيحًا.'; okMsg = false; }); return; }
    if (p.length < 6) { setState(() { err = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.'; okMsg = false; }); return; }
    setState(() { busy = true; err = ''; });
    final r = await sync.email(e, p, create);
    if (!mounted) return;
    setState(() => busy = false);
    if (r.error != null) {
      final m = r.error!;
      setState(() {
        okMsg = false;
        err = RegExp('already|registered', caseSensitive: false).hasMatch(m) ? 'هذا البريد مسجل بالفعل.' : RegExp('invalid|credentials', caseSensitive: false).hasMatch(m) ? 'البريد أو كلمة المرور غير صحيحة.' : m == 'no-client' ? 'لم يتم ضبط Supabase بعد.' : 'تعذّر إكمال العملية الآن، حاول مرة أخرى.';
      });
      return;
    }
    if (create && r.needsConfirm) {
      setState(() { okMsg = true; err = 'تم إنشاء الحساب. افحص بريدك الإلكتروني لتأكيد الحساب.'; });
    } else {
      hap.success();
      openRoute('home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return PageScaffold(title: 'تسجيل الدخول', children: [
      const SizedBox(height: 10),
      Center(child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Image.asset('assets/brand/app_icon.png', width: 84, height: 84))),
      const SizedBox(height: 12),
      const Center(child: Text('مزامنة تقدّمك', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700))),
      const Padding(padding: EdgeInsets.all(10), child: Sub('سجّل الدخول لتُحفظ ختمتك وسبحتك وأذكارك على حسابك وتظهر على أي جهاز.', align: TextAlign.center)),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: p.surf, foregroundColor: p.on, side: BorderSide(color: p.line)),
        onPressed: () async { final e = await sync.google(); if (e != null) toast(e); },
        icon: const Icon(Icons.g_mobiledata_rounded, size: 34), label: const Text('المتابعة بحساب Google'),
      ),
      const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Sub('أو بالبريد الإلكتروني', align: TextAlign.center)),
      TextField(controller: em, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'البريد الإلكتروني')),
      const SizedBox(height: 10),
      TextField(controller: pw, obscureText: hidden, textDirection: TextDirection.ltr, decoration: InputDecoration(hintText: 'كلمة المرور (6 أحرف على الأقل)', suffixIcon: IconButton(icon: Icon(hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded), onPressed: () => setState(() => hidden = !hidden)))),
      if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err, style: TextStyle(color: okMsg ? p.ok : const Color(0xFFA8332B)))),
      const SizedBox(height: 12),
      FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)), onPressed: busy ? null : go, child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(create ? 'إنشاء الحساب' : 'تسجيل الدخول')),
      TextButton(onPressed: () => setState(() { create = !create; err = ''; }), child: Text(create ? 'لديك حساب؟ سجل الدخول' : 'ليس لديك حساب؟ أنشئ حسابًا')),
      TextButton(onPressed: () => openRoute('home'), child: Text('تخطي · استخدام التطبيق بدون حساب', style: TextStyle(color: p.on2))),
    ]);
  }
}

class _Profile extends StatelessWidget {
  const _Profile();
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final u = sync.user!;
    final meta = u.userMetadata ?? {};
    final email = u.email ?? '';
    final name = (meta['full_name'] ?? meta['name'] ?? (email.isNotEmpty ? email.split('@').first : 'م')).toString();
    final prov = (u.appMetadata['provider'] ?? 'email') == 'google' ? 'حساب Google' : 'حساب بريد إلكتروني';
    final (icon, label, color) = switch (sync.status) {
      SyncStatus.ok => (Icons.check_circle_rounded, 'تمت المزامنة', p.ok),
      SyncStatus.syncing => (Icons.sync_rounded, 'جارٍ المزامنة…', p.pri),
      SyncStatus.offline => (Icons.cloud_off_rounded, 'لا يوجد اتصال، ستتم المزامنة عند عودته', const Color(0xFFA8332B)),
      SyncStatus.error => (Icons.cloud_off_rounded, 'تعذّرت المزامنة، سنحاول مرة أخرى تلقائيًا', const Color(0xFFA8332B)),
      SyncStatus.off => (Icons.cloud_off_rounded, 'غير مفعّلة', p.on2),
    };
    return PageScaffold(title: 'حسابي', children: [
      AppCard(margin: const EdgeInsets.only(top: 6), child: Row(children: [
        CircleAvatar(radius: 28, backgroundColor: p.pri, child: Text((name.isEmpty ? 'م' : name.substring(0, 1)).toUpperCase(), style: TextStyle(color: p.onpri, fontSize: 24, fontWeight: FontWeight.w700))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), Sub(email), Sub(prov)])),
      ])),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Expanded(child: Text('مزامنة التقدّم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))), Icon(icon, color: color)]),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color)),
        if (sync.last > 0) Sub('آخر مزامنة: ${DateTime.fromMillisecondsSinceEpoch(sync.last).toString().substring(0, 16)}'),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(onPressed: sync.status == SyncStatus.syncing ? null : () { hap.click(); sync.run(); }, icon: const Icon(Icons.sync_rounded), label: const Text('مزامنة الآن')),
      ])),
      AppCard(padding: EdgeInsets.zero, child: Column(children: [
        ListTile(title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w700)), trailing: const Icon(Icons.logout_rounded), onTap: () async { await sync.run(); await sync.logout(); toast('تم تسجيل الخروج'); openRoute('home'); }),
        Divider(height: 1, color: p.line),
        ListTile(
          title: const Text('حذف الحساب', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFA8332B))),
          trailing: const Icon(Icons.delete_outline_rounded, color: Color(0xFFA8332B)),
          onTap: () async {
            if (await confirmDialog(context, 'مسح الحساب نهائيًا؟', 'سيتم حذف حسابك وكل بياناتك المحفوظة على السيرفر. لا يمكن التراجع عن هذا الإجراء.', ok: 'مسح الحساب نهائيًا', danger: true)) {
              final ok = await sync.deleteAccount();
              toast(ok ? 'تم مسح حسابك.' : 'تعذر مسح الحساب. حاول مرة أخرى.');
              if (ok) openRoute('home');
            }
          },
        ),
      ])),
    ]);
  }
}
