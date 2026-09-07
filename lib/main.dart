import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/avaliation_store.dart';
import 'domain/models.dart';
import 'ui/common.dart';
import 'features/account.dart';
import 'features/teacher.dart';
import 'features/student.dart';
import 'features/results.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AvaliationStore(await SharedPreferences.getInstance());
  await store.carregar();
  runApp(AvaliaTechApp(store: store));
}

class AvaliaTechApp extends StatelessWidget {
  const AvaliaTechApp({super.key, required this.store});
  final AvaliationStore store;
  @override Widget build(BuildContext context) => AppScope(store: store, child: AnimatedBuilder(animation: store, builder: (context, _) {
    final dark = store.atual == null ? false : store.configuracao.temaEscuro;
    return MaterialApp(title: 'AvaliaTech', debugShowCheckedModeBanner: false, theme: appTheme(false), darkTheme: appTheme(true), themeMode: dark ? ThemeMode.dark : ThemeMode.light, home: store.autenticado ? const HomeShell() : const LoginPage());
  }));
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});
  @override Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ValueListenableBuilder<int>(valueListenable: AppNav.selected, builder: (context, index, _) {
      final isTeacher = store.professor;
      final titles = isTeacher ? ['Início', 'Minhas Turmas', 'Avaliações', 'Resultados'] : ['Início', 'Minhas Turmas', 'Avaliações', 'Perfil'];
      final subtitles = isTeacher ? ['Seu painel de ensino', 'Gerencie seus alunos e aulas', 'Gerencie seus questionários', 'Desempenho e engajamento das turmas'] : ['Sua jornada de aprendizado', 'Suas turmas em andamento', 'Gerencie seus exames e notas', 'Sua conta e preferências'];
      final screens = isTeacher ? <Widget>[const TeacherHome(), const TeacherClasses(), const TeacherEvaluations(), const ResultsHome()] : <Widget>[const StudentHome(), const StudentClasses(), const StudentEvaluations(), const ProfileContent()];
      return AppPage(title: titles[index], subtitle: subtitles[index], actions: [IconButton(tooltip:'Notificações',onPressed:()=>openPage(context,const NotificationsPage()),icon:Badge(isLabelVisible:store.minhasNotificacoes.any((n)=>!n.lida),child:const Icon(Icons.notifications_outlined))),if(isTeacher)IconButton(tooltip:'Perfil',onPressed:()=>openPage(context,const ProfilePage()),icon:CircleAvatar(radius:16,backgroundColor:AppColors.primary.withValues(alpha:.12),child:Text(store.usuario.nome.substring(0,1).toUpperCase(),style:const TextStyle(color:AppColors.primary,fontWeight:FontWeight.bold))))],scroll:false,child:screens[index]);
    });
  }
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  final email=TextEditingController(),senha=TextEditingController();
  Papel papel=Papel.professor;bool obscure=true,busy=false;
  @override void initState(){super.initState();email.text='ana.silva@escola.com.br';senha.text='12345678';}
  @override void dispose(){email.dispose();senha.dispose();super.dispose();}
  @override Widget build(BuildContext context){final store=AppScope.of(context);return Scaffold(body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Padding(padding:const EdgeInsets.all(28),child:Column(children:[Expanded(child:SingleChildScrollView(child:Column(children:[const SizedBox(height:38),Container(width:68,height:60,decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(17)),child:const Icon(Icons.menu_book_rounded,color:Colors.white,size:36)),const SizedBox(height:18),const Text('AvaliaTech',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900,color:AppColors.primary)),const SizedBox(height:6),const Text('Avaliações inteligentes para educação',textAlign:TextAlign.center,style:TextStyle(color:AppColors.muted)),const SizedBox(height:30),SegmentedButton<Papel>(segments:const [ButtonSegment(value:Papel.professor,label:Text('Professor')),ButtonSegment(value:Papel.estudante,label:Text('Estudante'))],selected:{papel},onSelectionChanged:(s){setState(()=>papel=s.first);email.text=papel==Papel.professor?'ana.silva@escola.com.br':'lucas.silva@aluno.com';}),const SizedBox(height:22),AppField('E-mail',controller:email,keyboardType:TextInputType.emailAddress),const SizedBox(height:16),AppField('Senha',controller:senha,obscure:obscure,suffix:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility_outlined:Icons.visibility_off_outlined))),Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>openPage(context,const PasswordHelpPage()),child:const Text('Esqueceu a senha?'))),const SizedBox(height:12),Text('Ambiente de demonstração local',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant,fontSize:12)),const SizedBox(height:5),const Text('As contas de exemplo usam a senha 12345678.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.muted,fontSize:12))])),const SizedBox(height:16),SizedBox(width:double.infinity,child:AppButton(busy?'Entrando...':'Entrar',onPressed:busy?null:()async{setState(()=>busy=true);await runAction(context,()=>store.entrar(email.text,senha.text,papel));if(mounted)setState(()=>busy=false);})),const SizedBox(height:8),TextButton(onPressed:()=>openPage(context,const RegisterPage()),child:const Text('Criar conta de demonstração'))]))))));}
}

class RegisterPage extends StatefulWidget {const RegisterPage({super.key});@override State<RegisterPage> createState()=>_RegisterPageState();}
class _RegisterPageState extends State<RegisterPage>{final nome=TextEditingController(),email=TextEditingController(),senha=TextEditingController();Papel papel=Papel.estudante;bool busy=false;@override void dispose(){nome.dispose();email.dispose();senha.dispose();super.dispose();}
@override Widget build(BuildContext context){final s=AppScope.of(context);return AppPage(title:'Criar conta',subtitle:'Cadastro local para demonstração',showNavigation:false,child:Column(children:[const Text('Os dados serão armazenados somente neste dispositivo. O cadastro não cria uma conta no servidor da instituição.'),const SizedBox(height:20),AppField('Nome completo',controller:nome),const SizedBox(height:14),AppField('E-mail',controller:email,keyboardType:TextInputType.emailAddress),const SizedBox(height:14),AppField('Senha (mínimo 8 caracteres)',controller:senha,obscure:true),const SizedBox(height:14),DropdownButtonFormField<Papel>(initialValue:papel,decoration:const InputDecoration(labelText:'Perfil'),items:const [DropdownMenuItem(value:Papel.estudante,child:Text('Estudante')),DropdownMenuItem(value:Papel.professor,child:Text('Professor'))],onChanged:(v){if(v!=null)setState(()=>papel=v);}),const SizedBox(height:24),AppButton(busy?'Aguarde...':'Cadastrar',onPressed:busy?null:()async{setState(()=>busy=true);final u=await runAction(context,()=>s.cadastrarUsuario(nome.text,email.text,senha.text,papel));if(!mounted)return;setState(()=>busy=false);if(u!=null){showMessage(context,'Conta criada. Faça seu login.');Navigator.pop(context);}})]);}}
class PasswordHelpPage extends StatelessWidget {const PasswordHelpPage({super.key});@override Widget build(BuildContext context)=>const AppPage(title:'Recuperar senha',showNavigation:false,child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.lock_reset,size:32,color:AppColors.primary),SizedBox(height:12),Text('Recuperação de acesso',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),SizedBox(height:8),Text('Este protótipo utiliza contas locais. Não há serviço de e-mail ou recuperação remota configurado. Para testar, utilize as contas de demonstração ou crie uma nova conta. Em produção, a recuperação deve ser feita por um servidor seguro.')])));}
