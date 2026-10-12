# Super Técnico 98: ROM de Super Nintendo (homenagem ao Elifoot 98)

Gerenciador de futebol no estilo do Elifoot 98, feito do zero em assembly 65816.
**`SuperTecnico98.sfc`** é uma ROM real de SNES (LoROM, 256 KB, 64 KB de SRAM com bateria).
Roda em emuladores (Mesen, bsnes, Snes9x) e em cartucho flash (FXPAK, EverDrive).

## Como jogar
1. Abra `SuperTecnico98.sfc` num emulador (há um Mesen em `tools/mesen/Mesen.exe`).
2. **NOVO JOGO** → escolha um dos 3 espaços de save → digite o nome do técnico → escolha o time
   (**← →** troca a série, **A** escolhe, **X** sorteia um time da Série D).
3. **Menu do clube**, em botões com ícones (direcional nas quatro direções; no topo: série, rodada, caixa, posição e a **meta da diretoria**, próximo jogo, situação na copa e a confiança da diretoria):
   - **JOGAR**: a próxima data (30 rodadas do campeonato e 12 datas da Copa do Brasil intercaladas).
   - **ESCALAÇÃO**: **A** titular/reserva/fora, **Y** à venda, **R** renova o contrato (paga luvas), **X** escala sozinho, **L** troca a tática (4-4-2, 4-3-3, 3-5-2, 5-3-2, 4-5-1, 3-4-3) e já escala, **SELECT** estilo.
     Colunas C = anos de contrato e M = moral (↑ animado, ↓ desanimado).
   - **TREINO**: equilibrado, ataque, defesa ou físico (metade das lesões).
   - **TABELA** e **JOGOS** (resultados e artilheiros, com escudinhos nas cores dos clubes): **← →** outras séries. Em JOGOS, **X** mostra o **calendário** com os próximos adversários.
   - **COPA**: os confrontos da fase, com o placar da ida.
   - **MERCADO**: lista de transferências ou procurar em qualquer clube. Na **negociação**, ajuste o valor (**← → ↑ ↓**) e faça a proposta: o clube aceita, faz contraproposta ou recusa. Titular custa mais caro.
   - **FINANÇAS**: receitas e despesas, preço do ingresso, **ampliar o estádio** (+2000 lugares) e **empréstimo** (pedir ou pagar, 2% de juros por data).
   - **CARREIRA**: reputação, jogos, vitórias, acessos, demissões e o histórico de campeões. **X** pede demissão.
   - **SALVAR E SAIR**. O jogo salva sozinho depois de cada jogo. **SELECT** liga e desliga a música.
4. **Partida ao vivo**: placar grande com os escudos, os outros jogos e os lances (gols, pênaltis, gols contra, cartões, lesões).
   Segure **A** para acelerar; **START** abre as substituições (também no intervalo); **L** e **R** mostram os jogos das outras séries.
5. **Depois do jogo**: gols com minuto, destaque do time, chutes a gol e posse de bola, dinheiro, diretoria, quem melhorou no treino e notícias do mercado.
6. **Fim da temporada**: prêmios (artilheiro de cada série, melhor goleiro e craque da sua série; premiado do seu time vale dinheiro), campeões das séries e da copa, acesso (4 sobem) e rebaixamento (4 caem), prêmio, envelhecimento, aposentadorias, garotos da base e contratos vencidos.
   Rebaixado, ou com a confiança da diretoria em zero, você é demitido e escolhe outro clube. Campanha boa traz convites.
7. **Carreira e seleção**: vencer, subir e cumprir a meta aumentam a reputação, e com ela vêm convites de clubes maiores até no meio da temporada. Depois das rodadas 8, 16 e 24 os craques (força 46+) vão para a seleção e perdem um jogo (SEL na escalação).

## Conteúdo
- Interface em azul-marinho com botões arredondados (principal em azul vibrante, positivo em verde, crítico em vermelho), faixa de seleção nas listas, símbolos dos botões A/B/X/Y nas cores do controle, caixas de confirmação nas ações que gastam dinheiro e avisos de sucesso ou erro.
- 64 clubes brasileiros reais em 4 séries, com escudo nas cores do clube, torcida e estádio; 1.408 jogadores inventados (editáveis).
- Copa do Brasil com 64 clubes, ida e volta, pênaltis e prêmio por fase (campeão: R$ 6 milhões).
- Moral (influi na força), contratos e renovação, treino, diretoria com barra de confiança, banco e estádio ampliável.
- Clubes da IA comprando e vendendo entre si (notícias no fim da rodada).
- Trilha original (rock de futebol na abertura e groove nos menus) com bateria, baixo slap, guitarra, metais e cordas.

## Editar times e jogadores
Abra `editor.html` no navegador, edite e salve o `elenco.json`, depois dê dois cliques em **`GERAR ROM.bat`**.
Regras: nomes com até 12 letras, sigla com 3, de 16 a 26 jogadores por clube (com goleiro) e 16 clubes por série.
A lista de clubes de 2026 foi montada de memória: confira as Séries C e D no editor.

## Cartucho, manual e trailer
- `cartucho/etiqueta_formato_classico.png`: etiqueta no formato clássico (com a capa).
- `cartucho/capa_jogo.png`: arte da capa em alta resolução.
- `cartucho/manual_super_tecnico_98.pdf`: manual A5 de 8 páginas, também em PNG por página.
- `trailer/trailer_super_tecnico_98.mp4`: trailer de 54 s em 1080p com cenas reais, a música do jogo e narração.
- Para refazer: `python gerador/capa.py`, `python gerador/cartucho.py`, `python gerador/trailer.py`.
  As fotos saem de `teste/fotos_manual.lua` e os quadros do trailer de `teste/grava.lua` (Mesen de testes).

## Recompilar
Requer Node.js. `node build.js` lê o `elenco.json`, gera a fonte, as telas, os instrumentos, a música e as tabelas, e monta a ROM com o cc65.
- `gerador/`: elenco padrão, regras (valores, salários, chance de gol, tabela de jogos, calendário e prêmios), arte, fonte, textos, instrumentos e música.
- `src/`: código 65816 (`main.s` núcleo, `mundo.s` e `calendario.s` regras e copa, `partida.s` jogo ao vivo, `telas.s`, `telas2.s`, `menus.s`, `mercado.s` telas, `carreira.s` carreira, prêmios, calendário, seleção e escudinhos, `save.s` SRAM, `audio.s` som).
- `teste/sim.js`: simulador de calibração; `teste/previa_musica.js`: prévia das músicas em WAV.
- `teste/bot.lua`, `teste/mercado.lua` e `teste/dialogos.lua`: robôs que jogam sozinhos no Mesen de testes (roteiro em `teste/botcfg.lua`). Use `--testrunner --timeout=900` em testes longos: o Mesen encerra sozinho depois de 100 s.
- `src/ui.s` e `gerador/ui.js`: componentes da interface (botão, painel, faixa, confirmação, aviso). Ícones do menu: emojis Twemoji (CC-BY 4.0).

## Cartucho
- LoROM, 256 KB, cabeçalho e checksum válidos, NTSC.
- Usa **64 KB de SRAM** (3 saves de 16 KB). Flashcarts aceitam. Numa placa com 32 KB, os dois primeiros saves funcionam e o terceiro, não.
- Saves da versão anterior continuam abrindo: a carreira e a meta são criadas na primeira vez que o jogo é carregado.
