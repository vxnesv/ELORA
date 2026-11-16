# Segurança e privacidade da ELORA

## Classificação dos dados

Registros de saúde, condições crônicas, insulina, ciclo menstrual, sintomas, anotações e contatos são tratados como dados sensíveis. Tema e tamanho de texto são preferências comuns.

## Controles implementados

- Firebase Authentication para identidade e sessão.
- Validação do ID token e de revogação no backend.
- UID obtido do token validado, nunca aceito como autoridade enviada pelo cliente.
- API sem sessão, com CORS restrito, HSTS, bloqueio de frames e política de conteúdo.
- Wallet e credenciais excluídos do repositório.
- `ELORA_RUNTIME` separado do proprietário `ELORA_APP` e sem privilégios de DDL.
- Oracle Autonomous com criptografia TDE em repouso e TLS/mTLS em trânsito.
- Componente AES-256-GCM implementado e testado para campos de maior sensibilidade, com contexto por usuário/campo; será aplicado quando os endpoints desses campos forem adicionados.
- Dados funcionais locais no armazenamento seguro do sistema; preferências visuais continuam no `SharedPreferences`.
- Backup Android do armazenamento do app desativado para evitar cópia sem a chave do Keystore.
- Tráfego HTTP sem TLS bloqueado na configuração Android principal.
- Build de produção não reutiliza a chave de assinatura debug.

## Chaves e segredos

Senhas, wallet, conta de serviço Firebase e chave de criptografia nunca são incluídos no código. Em produção, devem ser injetados por um gerenciador de segredos. A chave de campos deve conter 32 bytes aleatórios codificados em Base64 e ser rotacionável por versão.

## Logs e notificações

Tokens, métricas, diagnósticos, ciclo e textos do usuário não podem aparecer em logs. As notificações de medicamento usam texto genérico e visibilidade privada; nome, dose e condição não aparecem na tela bloqueada. O conteúdo completo só aparece após abrir o aplicativo autenticado.

## Retenção e controle

O usuário deve poder consultar as permissões, desconectar Health Connect/HealthKit, exportar um resumo e solicitar exclusão. A integração coleta somente os tipos selecionados e mantém a origem e o horário de cada registro.

## Pendências antes de produção

- Armazenar a chave principal no OCI Vault ou serviço equivalente.
- Implementar rotação e recriptografia por versão.
- Aplicar `SensitiveDataCipher` aos endpoints de anotações, condições crônicas, ciclo e medicação.
- Criar rotinas de leitura no pacote Oracle para eliminar SELECT direto.
- Adicionar limitação de requisições no gateway de implantação.
- Executar testes de autorização entre duas contas próprias.
- Definir política de retenção, resposta a incidentes e texto de consentimento.
- Configurar e proteger a chave de assinatura da versão Android de produção.

