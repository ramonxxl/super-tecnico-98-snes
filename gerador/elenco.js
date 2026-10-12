// Gera o elenco.json padrao (64 clubes reais, jogadores inventados).
// Uso: node gerador/elenco.js [--forcar]   (nao sobrescreve um elenco ja editado)
'use strict';
const fs = require('fs'), path = require('path');

// [nome (ate 12), sigla, fama 1-10, capacidade, cor1, cor2]
const CLUBES = [
  // Serie A
  ['FLAMENGO', 'FLA', 10, 78000, '#D01818', '#101010'],
  ['PALMEIRAS', 'PAL', 10, 43000, '#107030', '#F8F8F8'],
  ['CORINTHIANS', 'COR', 10, 49000, '#F8F8F8', '#101010'],
  ['SÃO PAULO', 'SAO', 9, 66000, '#F8F8F8', '#D01818'],
  ['ATLÉTICO-MG', 'CAM', 9, 46000, '#101010', '#F8F8F8'],
  ['BOTAFOGO', 'BOT', 8, 44000, '#101010', '#F8F8F8'],
  ['FLUMINENSE', 'FLU', 8, 78000, '#801830', '#107030'],
  ['GRÊMIO', 'GRE', 8, 55000, '#2878D0', '#101010'],
  ['INTER', 'INT', 8, 50000, '#D01818', '#F8F8F8'],
  ['CRUZEIRO', 'CRU', 8, 61000, '#1840B0', '#F8F8F8'],
  ['VASCO', 'VAS', 8, 21000, '#101010', '#F8F8F8'],
  ['SANTOS', 'SAN', 8, 16000, '#F8F8F8', '#101010'],
  ['BAHIA', 'BAH', 7, 48000, '#1840B0', '#D01818'],
  ['ATHLETICO-PR', 'CAP', 7, 42000, '#D01818', '#101010'],
  ['BRAGANTINO', 'RBB', 6, 15000, '#F8F8F8', '#D01818'],
  ['VITÓRIA', 'VIT', 6, 30000, '#D01818', '#101010'],
  // Serie B
  ['FORTALEZA', 'FOR', 7, 63000, '#1840B0', '#D01818'],
  ['SPORT', 'SPO', 7, 28000, '#D01818', '#101010'],
  ['CEARÁ', 'CEA', 6, 63000, '#101010', '#F8F8F8'],
  ['CORITIBA', 'CFC', 6, 40000, '#107030', '#F8F8F8'],
  ['JUVENTUDE', 'JUV', 5, 19000, '#107030', '#F8F8F8'],
  ['MIRASSOL', 'MIR', 5, 15000, '#F8D820', '#107030'],
  ['REMO', 'REM', 6, 45000, '#1838A0', '#F8F8F8'],
  ['CHAPECOENSE', 'CHA', 5, 22000, '#107030', '#F8F8F8'],
  ['GOIÁS', 'GOI', 5, 14000, '#107030', '#F8F8F8'],
  ['CUIABÁ', 'CUI', 4, 44000, '#F8D820', '#107030'],
  ['AMÉRICA-MG', 'AME', 5, 18000, '#107030', '#101010'],
  ['ATLÉTICO-GO', 'ACG', 4, 12000, '#D01818', '#101010'],
  ['NOVORIZONTIN', 'NOV', 4, 16000, '#F8D820', '#101010'],
  ['CRICIÚMA', 'CRI', 4, 19000, '#F8D820', '#101010'],
  ['AVAÍ', 'AVA', 4, 17000, '#2878D0', '#F8F8F8'],
  ['VILA NOVA', 'VIL', 4, 11000, '#D01818', '#F8F8F8'],
  // Serie C
  ['PONTE PRETA', 'PON', 5, 19000, '#101010', '#F8F8F8'],
  ['GUARANI', 'GUA', 5, 29000, '#107030', '#F8F8F8'],
  ['PAYSANDU', 'PAY', 5, 16000, '#2878D0', '#F8F8F8'],
  ['NÁUTICO', 'NAU', 4, 19000, '#D01818', '#F8F8F8'],
  ['CRB', 'CRB', 4, 19000, '#D01818', '#F8F8F8'],
  ['OPERÁRIO-PR', 'OPE', 3, 10000, '#101010', '#F8F8F8'],
  ['BOTAFOGO-SP', 'BSP', 3, 15000, '#D01818', '#F8F8F8'],
  ['LONDRINA', 'LON', 3, 30000, '#2878D0', '#F8F8F8'],
  ['FIGUEIRENSE', 'FIG', 4, 19000, '#101010', '#F8F8F8'],
  ['ITUANO', 'ITU', 3, 18000, '#D01818', '#101010'],
  ['ABC', 'ABC', 4, 18000, '#101010', '#F8F8F8'],
  ['SÃO BERNARDO', 'SBE', 3, 15000, '#F8D820', '#101010'],
  ['FERROVIÁRIA', 'FER', 3, 20000, '#801830', '#F8F8F8'],
  ['AMAZONAS', 'AMA', 3, 44000, '#F8D820', '#101010'],
  ['VOLTA REDOND', 'VRE', 3, 18000, '#F8D820', '#101010'],
  ['ATHLETIC-MG', 'ATH', 2, 10000, '#101010', '#F8F8F8'],
  // Serie D
  ['SANTA CRUZ', 'STA', 5, 60000, '#D01818', '#101010'],
  ['PORTUGUESA', 'POR', 4, 18000, '#D01818', '#107030'],
  ['PARANÁ', 'PAR', 4, 20000, '#1840B0', '#D01818'],
  ['AMÉRICA-RN', 'AMR', 3, 18000, '#D01818', '#F8F8F8'],
  ['SAMPAIO', 'SAM', 3, 40000, '#F8D820', '#D01818'],
  ['CSA', 'CSA', 3, 19000, '#2878D0', '#F8F8F8'],
  ['JOINVILLE', 'JEC', 3, 22000, '#D01818', '#101010'],
  ['BRUSQUE', 'BRU', 2, 5000, '#F8D820', '#107030'],
  ['BOTAFOGO-PB', 'BPB', 2, 20000, '#101010', '#F8F8F8'],
  ['TREZE', 'TRE', 2, 15000, '#101010', '#F8F8F8'],
  ['CONFIANÇA', 'CON', 2, 15000, '#1840B0', '#F8F8F8'],
  ['YPIRANGA-RS', 'YPI', 2, 6000, '#F8D820', '#107030'],
  ['CAXIAS', 'CAX', 2, 22000, '#801830', '#F8F8F8'],
  ['TOMBENSE', 'TOM', 1, 4000, '#D01818', '#F8F8F8'],
  ['XV DE PIRA', 'XVP', 2, 18000, '#101010', '#F8F8F8'],
  ['INTER LIMEIR', 'ILI', 2, 18000, '#101010', '#F8F8F8'],
];

const PRIMEIROS = ['GABRIEL', 'LUCAS', 'MATHEUS', 'PEDRO', 'RAFAEL', 'BRUNO', 'DIEGO', 'FELIPE', 'GUSTAVO', 'THIAGO',
  'RODRIGO', 'ANDRÉ', 'MARCOS', 'JOÃO', 'CARLOS', 'PAULO', 'RENATO', 'FÁBIO', 'LEANDRO', 'EDUARDO', 'VITOR',
  'DANIEL', 'RICARDO', 'SAMUEL', 'CAIO', 'IGOR', 'HUGO', 'WESLEY', 'ÉVERTON', 'ALEX', 'JORGE', 'LUIZ', 'MAURO',
  'NATAN', 'OTÁVIO', 'RAUL', 'SÉRGIO', 'TIAGO', 'VINÍCIUS', 'WILLIAN', 'YAGO', 'ARTHUR', 'BERNARDO', 'CLEITON',
  'DAVI', 'ÉRICK', 'FERNANDO', 'GILBERTO', 'HENRIQUE', 'ÍTALO', 'JEFERSON', 'KAUÃ', 'LÉO', 'MÁRCIO', 'NILTON',
  'ROBSON', 'SIDNEY', 'TÚLIO', 'VAGNER', 'WALLACE', 'ADRIANO', 'BRENO', 'CÉSAR', 'DOUGLAS', 'ELIAS', 'FABRÍCIO'];
const SOBRENOMES = ['SILVA', 'SOUZA', 'COSTA', 'SANTOS', 'OLIVEIRA', 'PEREIRA', 'LIMA', 'ALVES', 'RIBEIRO', 'GOMES',
  'MARTINS', 'ROCHA', 'DIAS', 'NUNES', 'MOURA', 'CRUZ', 'MELO', 'BRAGA', 'PIRES', 'LOPES', 'FARIAS', 'REIS',
  'TEIXEIRA', 'MENDES', 'BARROS', 'FREITAS', 'CAMPOS', 'VIEIRA', 'CARDOSO', 'MACEDO', 'ARAÚJO', 'BORGES', 'FONSECA',
  'MATOS', 'PRADO', 'QUEIROZ', 'SALES', 'TORRES', 'VALE', 'XAVIER'];
const APELIDOS = ['TIQUINHO', 'MARCÃO', 'DUDU', 'ZÉ ROBERTO', 'BIRO', 'PIKACHU', 'TOQUINHO', 'NENÊ', 'DIDI', 'PELEZINHO',
  'CHICÃO', 'JUNINHO', 'ROMARINHO', 'BEBETO', 'CAFU', 'ZINHO', 'MULLER', 'CANHOTO', 'BOLA', 'TINGA', 'BIGODE',
  'TITA', 'CACAU', 'PIPOCA', 'GORDO', 'NEGUEBA', 'FRED', 'KAKÁ', 'DECO', 'ROGÉRIO', 'BETINHO', 'CARECA', 'DODÔ',
  'FUMAÇA', 'GALEGO', 'JACARÉ', 'LULINHA', 'MAGRÃO', 'NINO', 'PATO', 'QUEIXADA', 'RATINHO', 'SABIÁ', 'TATU',
  'VAVÁ', 'XUXA', 'ZEZINHO', 'BOMBA', 'CORISCO', 'FOGUINHO', 'GUGA', 'JAJÁ', 'LELÊ', 'MOSQUITO', 'PEPÊ',
  'BAIANO', 'MINEIRO', 'PAULISTA', 'GAÚCHO', 'CEARENSE', 'CARIOCA', 'PARAÍBA', 'MARANHÃO', 'GOIANO'];

// gerador pseudo-aleatorio deterministico
let seed = 19980;
function rnd() { seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF; return seed / 0x80000000; }
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1));
const pick = (arr) => arr[Math.floor(rnd() * arr.length)];

const usados = new Set();
function nomeNovo() {
  for (let t = 0; t < 200; t++) {
    const r = rnd();
    let n;
    if (r < 0.25) n = pick(APELIDOS);
    else if (r < 0.55) n = pick(PRIMEIROS);
    else if (r < 0.85) n = pick(PRIMEIROS) + ' ' + pick(SOBRENOMES);
    else n = pick(PRIMEIROS)[0] + '. ' + pick(SOBRENOMES);
    if (n.length > 12) n = n.split(' ')[0];
    if (!usados.has(n)) { usados.add(n); return n; }
  }
  // fallback com inicial
  for (;;) { const n = (pick(PRIMEIROS)[0] + '. ' + pick(SOBRENOMES) + ' ' + ri(1, 9)).slice(0, 12); if (!usados.has(n)) { usados.add(n); return n; } }
}

// forca media por divisao e ajuste pela fama do clube
const BASE = [36, 26, 18, 12];
const POS = ['G', 'G', 'G', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'A', 'A', 'A', 'A', 'A'];

function gerar() {
  const clubes = CLUBES.map(([nome, sigla, fama, capacidade, cor1, cor2], i) => {
    const div = Math.floor(i / 16);
    const media = BASE[div] + Math.round((fama - 5) * 1.6);
    const jogadores = POS.map((pos, j) => {
      const titular = (pos === 'G' && j === 0) || (pos === 'D' && j < 7) || (pos === 'M' && j < 14) || (pos === 'A' && j < 19);
      const f = Math.max(1, Math.min(50, media + ri(-4, 5) + (titular ? 3 : -3)));
      return { nome: nomeNovo(), pos, forca: f, idade: ri(18, 34) };
    });
    return { nome, sigla, divisao: ['A', 'B', 'C', 'D'][div], fama, capacidade, cores: [cor1, cor2], jogadores };
  });
  const base = [];
  while (base.length < 1100) base.push(nomeNovo());
  return { versao: 1, observacao: 'Edite com editor.html e rode node build.js para gerar a ROM nova.', clubes, nomesBase: base };
}

if (require.main === module) {
  const out = path.join(__dirname, '..', 'elenco.json');
  if (fs.existsSync(out) && !process.argv.includes('--forcar')) {
    console.log('elenco.json ja existe (use --forcar para recriar).');
  } else {
    fs.writeFileSync(out, JSON.stringify(gerar(), null, 1));
    console.log('elenco.json criado.');
  }
}
module.exports = { gerar };
