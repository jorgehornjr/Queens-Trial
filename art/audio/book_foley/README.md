# Som do livro

`page_turn.wav` é um efeito original de 1,04 s para a passagem de uma folha: ruído de fibras filtrado, movimento suave e quatro pequenos vincos. `book_close.wav` dura 1,25 s e combina tecido com um contato discreto no fim do fechamento. Ambos são estéreo, 48 kHz e 16 bits, sem gravações de terceiros.

Preparação reproduzível em `tools/create_book_foley.py`, com NumPy e semente fixa. Medições dos arquivos em [report.json](report.json). O Godot aplica +6 dB ao folhear e +8 dB ao fechar. Virar uma folha bloqueada não emite som; cancelar a leitura interrompe os dois efeitos. A leve mudança de pitch ao voltar evita que toda passagem soe idêntica.
