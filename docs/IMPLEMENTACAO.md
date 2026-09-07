# AvaliaTech — implementação

Este projeto implementa o aplicativo educacional em Flutter a partir do modelo de classes, dos fluxos do Professor e do Estudante e do PDF de telas fornecidos pelo autor.

## Invariantes

- Questionário é um conteúdo reutilizável, independente de qualquer publicação.
- Cada publicação tem identidade, turmas, datas, tentativas e resultados próprios.
- As ações finais de criação são Criar e Criar e publicar, sem estado de rascunho.
- O Professor possui as abas Início, Turmas, Avaliações e Resultados; perfil e notificações ficam no topo.
- O Estudante possui Início, Turmas, Avaliações e Perfil; a barra inferior desaparece durante a tentativa.
- Resultados são acessados pelo dashboard de uma publicação, com filtros e aprofundamentos.
- Uma resposta submetida não pode ser alterada pelo estudante. Correções manuais não devem ser confundidas com correção automática.

## Estado da implementação

A implementação está sendo desenvolvida na branch feature/flutter-avaliatech. Este documento não constitui confirmação de que o aplicativo esteja compilado ou pronto para produção. A autenticação remota, sincronização entre dispositivos e infraestrutura de servidor exigem configuração e validação próprias.
