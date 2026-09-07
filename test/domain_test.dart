import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avaliatech/data/avaliation_store.dart';
import 'package:avaliatech/domain/models.dart';

void main(){
  late AvaliationStore s;
  setUp(()async{SharedPreferences.setMockInitialValues({});s=AvaliationStore(await SharedPreferences.getInstance());await s.carregar();});
  tearDown((){s.dispose();});
  Future<void> teacher() => s.entrar('ana.silva@escola.com.br','12345678',Papel.professor);
  Future<void> student() => s.entrar('lucas.silva@aluno.com','12345678',Papel.estudante);
  Future<Questionario> buildQuiz()async{
    final now=DateTime.now();
    final q=Questao(id:newId(),professorId:s.uid,enunciado:'Quanto é 2 + 2?',disciplina:'Matemática',tipo:TipoQuestao.multiplaEscolha,dataCriacao:now,dataAtualizacao:now,alternativas:[Alternativa(id:'wrong',texto:'3',ordem:0),Alternativa(id:'right',texto:'4',ordem:1,correta:true)]);
    await s.salvarQuestao(q);
    return s.salvarQuestionario(Questionario(id:newId(),professorId:s.uid,titulo:'Teste matemático',descricao:'Teste',dataCriacao:now,dataAtualizacao:now,itens:[ItemQuestionario(id:newId(),questionarioId:'test',questaoId:q.id,ordem:0,pontuacao:2)]));
  }
  Future<PublicacaoQuestionario> publish(Questionario q,{int limit=1,bool show=true})=>s.publicar(questionarioId:q.id,turmaIds:['demo-turma'],inicio:DateTime.now().subtract(const Duration(hours:1)),prazo:DateTime.now().add(const Duration(days:1)),limite:limit,mostrarResultado:show,embaralhar:false);
  test('questionnaire is independent from repeatable publications and snapshots',()async{
    await teacher();final q=await buildQuiz();final first=await publish(q);final second=await publish(q);
    expect(first.id,isNot(second.id));expect(first.questionarioId,q.id);expect(second.questionarioId,q.id);
    final item=first.conteudo!.itens.first;expect(item.pontuacao,2);
    final original=s.questao(item.questaoId);final edited=original.snapshot()..enunciado='Enunciado atualizado';await s.salvarQuestao(edited);
    expect(s.conteudo(first).questao(item.questaoId).enunciado,'Quanto é 2 + 2?');expect(s.conteudo(second).questao(item.questaoId).enunciado,'Quanto é 2 + 2?');
    expect(s.questao(item.questaoId).enunciado,'Enunciado atualizado');
  });
  test('a student cannot create classes or publish questions',()async{
    await student();await expectLater(s.salvarTurma(nome:'Invasão',disciplina:'Teste'),throwsA(isA<AvaliaTechException>()));
    await expectLater(s.publicar(questionarioId:'demo-questionario',turmaIds:['demo-turma'],inicio:DateTime.now(),prazo:DateTime.now().add(const Duration(days:1)),limite:1,mostrarResultado:true,embaralhar:false),throwsA(isA<AvaliaTechException>()));
  });
  test('attempts preserve answers, enforce limits and become immutable',()async{
    await teacher();final p=await publish(await buildQuiz());await student();final t=await s.iniciar(p.id);final q=s.conteudo(p).questoes.first;
    await s.responder(t.id,q.id,alternativaId:'wrong');await s.responder(t.id,q.id,alternativaId:'right');
    expect(t.resposta(q.id)!.alternativaSelecionadaId,'right');
    final r=await s.enviar(t.id);expect(r.nota,10);expect(r.acertos,1);expect(t.editavel,false);expect(s.podeIniciar(p),false);
    await expectLater(s.responder(t.id,q.id,alternativaId:'wrong'),throwsA(isA<AvaliaTechException>()));
    await expectLater(s.iniciar(p.id),throwsA(isA<AvaliaTechException>()));
  });
  test('manual correction keeps partial results pending until graded',()async{
    await student();final t=await s.iniciar('demo-publicacao');final c=s.conteudo(s.publicacao(t.publicacaoId));final essay=c.questoes.firstWhere((q)=>q.tipo==TipoQuestao.dissertativa);
    await s.responder(t.id,essay.id,texto:'Listas são mutáveis e tuplas são imutáveis.');final r=await s.enviar(t.id);expect(r.provisorio,true);expect(t.status,StatusTentativa.enviada);
    await teacher();expect(s.correcoesPendentes.any((e)=>e.id==t.id),true);await s.corrigirResposta(t.id,essay.id,4);
    expect(s.resultadoDaTentativa(t.id)!.provisorio,false);expect(s.resultadoDaTentativa(t.id)!.nota,4);expect(t.status,StatusTentativa.corrigida);
  });
  test('hidden results cannot be accessed by students',()async{
    await teacher();final p=await publish(await buildQuiz(),show:false);await student();final t=await s.iniciar(p.id);await s.enviar(t.id);
    expect(()=>s.exigirResultadoVisivel(t),throwsA(isA<AvaliaTechException>()));await teacher();expect(()=>s.exigirResultadoVisivel(t),returnsNormally);
  });
  test('dashboard calculates real metrics and handles empty data',()async{
    await teacher();final p=await publish(await buildQuiz());var m=s.metricas(p.id);expect(m.media,isNull);expect(m.taxaParticipacao,0);
    await student();final t=await s.iniciar(p.id);await s.responder(t.id,s.conteudo(p).questoes.first.id,alternativaId:'right');await s.enviar(t.id);
    await teacher();m=s.metricas(p.id);expect(m.media,10);expect(m.mediana,10);expect(m.totalRespondentes,1);expect(m.taxaParticipacao,100);expect(m.distribuicaoNotas.last.quantidade,1);
  });
  test('state survives a reload on the same device',()async{
    await teacher();final q=await buildQuiz();final p=await publish(q);await s.sair();final reloaded=AvaliationStore(await SharedPreferences.getInstance());await reloaded.carregar();
    expect(reloaded.questionario(q.id).titulo,q.titulo);expect(reloaded.publicacao(p.id).conteudo!.questoes.first.enunciado,'Quanto é 2 + 2?');expect(reloaded.atual,isNull);reloaded.dispose();
  });
  test('scheduled and ended publication windows block new attempts',()async{
    await teacher();final q=await buildQuiz();final future=await s.publicar(questionarioId:q.id,turmaIds:['demo-turma'],inicio:DateTime.now().add(const Duration(days:1)),prazo:DateTime.now().add(const Duration(days:2)),limite:1,mostrarResultado:true,embaralhar:false);
    expect(future.estado(),StatusPublicacao.agendada);await student();expect(s.podeIniciar(future),false);
    await teacher();await s.ajustarPublicacao(future.id,encerrar:true);expect(future.estado(),StatusPublicacao.encerrada);await student();expect(s.podeIniciar(future),false);
  });
}
