# Wind e Candle fornecidos pelo usuário

Os MP3 originais estão arquivados nesta pasta, com hashes em `preparation_report.json`. A versão atual não utiliza a trilha de American Horror Story nem os ventos sintéticos anteriores.

- Wind: trecho de 0,8–1,75 s para a descida dos pratos; trecho de 2,0–4,3 s para a inclinação/deslizamento. Fades curtos e um pequeno balanço entre os canais acompanham esquerda/direita. Os ganhos e volumes são mais baixos que os efeitos anteriores. A reprodução é pausada, cancelada ou encerrada junto à gameplay.
- Candle: trecho de 1,0–2,65 s, com 1,65 s de duração, igual a `CardPresentation.BURN_DURATION`. O transiente de apagamento perto do fim do MP3 fica fora do recorte. O ganho preserva a dinâmica e limita a amplificação para evitar saturação; não há compressão ou síntese.

Reprodução: `python tools/prepare_user_presentation_audio.py`. Os utilitários antigos de vento e AHS agora gravam somente referências arquivadas, sem sobrescrever os áudios atuais.
