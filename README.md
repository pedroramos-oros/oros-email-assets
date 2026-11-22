# oros-email-assets

Imagens dos e-mails da Oros (lives, newsletter, boas-vindas). Repositório público e permanente: serve de hospedagem de origem para o Beehiiv buscar as imagens (`save_image`) e para os próximos e-mails quando a operação escalar.

## Arquivos (e-mail "É hoje", versão 2)

| Arquivo | Uso |
| --- | --- |
| `hero-transparente.png` (atual) e `hero.jpg` (antigo, cantos brancos) | Topo do cartão: selo, título da live, foto do Matteo e adesivos (1200x760) |
| `header.png` | Logo Oros Data sobre o fundo papel (transparente) |
| `strip.png` | Faixa "Hoje, 19h (Brasília)" com ícone de calendário (transparente) |
| `ic-yt.png`, `ic-ig.png`, `ic-wa.png`, `ic-web.png` | Ícones do rodapé (transparentes, 56x56) |

O título do `hero.jpg` muda a cada live, então esse arquivo é regerado por live.

## Gerador do topo (`gerador/`)

Fontes usadas para gerar as imagens acima, no macOS, sem navegador instalado.

1. `snap.swift` renderiza uma página HTML em PNG usando o WebKit do sistema: `swiftc -O -o snap snap.swift`, depois `./snap <url> <saida.png> <largura> <altura> [timeout] [transparent]`.
2. `cutout.swift` recorta a pessoa de uma foto (Vision): `./cutout <foto> <saida.png> cropX cropY cropW cropH elipseCX elipseCY elipseRX elipseRY elipseRX2 elipseRY2`. O recorte pronto do Matteo é `matteo-cut.png`.
3. `hero.html` é o topo (600x380; saída 1200x760). O título fica na tag `<h1>`. Troque o texto e a palavra em âmbar (`<span class="a">`) a cada live.
4. `header.html`, `strip.html` e `icon.html?k=yt|ig|wa|web` geram logo, faixa de data e ícones.

Para renderizar, sirva esta pasta por HTTP local, copie as fontes da marca para `fonts/` (JetBrains Mono 500/700/800 e IBM Plex Sans 400/500/600, do manual de marca), copie `oros-polvo.svg`, `oros-logo-oficial.svg` e `header-old.png` (logo antigo do Beehiiv, usado só para extrair a palavra "OROS DATA") para a mesma pasta, e exporte o `hero` como JPEG (`sips -s format jpeg -s formatOptions 84`).

Nota: o topo precisa ser PNG com cantos superiores transparentes (raio 24 px à esquerda e 22 px à direita), senão os cantos retangulares da imagem cobrem o arco preto do cartão no Beehiiv. Renderize com `./snap ... transparent`.

## E-mail "Falta 1 hora"

`hero-falta-1h.png` é o topo desse e-mail (gerado por `gerador/hero-1h.html`): título "Falta 1h pra live", subtítulo com o tema, contagem regressiva e relógio. Mesmas regras: PNG com cantos superiores transparentes.

## E-mail "Estamos ao vivo agora"

`hero-ao-vivo.png` (gerado por `gerador/hero-aovivo.html`): selo "AO VIVO AGORA", título "Estamos ao vivo", subtítulo com o tema, painel "Transmitindo agora" e botão de play. É o e-mail mais curto dos três.

## Newsletter v2 (design ousado)

`news-masthead.png`, `news-ia.png`, `news-neg.png`, `news-rap.png`, `news-pen.png` e `news-live.png`: topo da edição e cabeçalhos de seção (IA, Negócios, Rapidinhas, Pra pensar, Ao vivo), gerados por `gerador/news.html?k=<nome>` (renderizar com `./snap ... transparent`; alturas: masthead 380, live 300, demais 150). O polvo ganha adereços por seção (óculos e jornal, antena, moeda, raio, lâmpada). Paleta: âmbar suave #FFD27F, verde-água #BFE3DC, creme #FFF3D6, noite #0D0C08, âmbar #E89E00.

### Imagens leves (`*-leve.png`)

As ilustrações da newsletter foram comprimidas para PNG de paleta (48 a 64 cores, com transparência): `news-*-leve.png`, somando cerca de 190 KB contra 860 KB das versões originais. Para recomprimir: `./rgba entrada.png saida.raw` (Swift, `gerador/rgba.swift`) e `python3 -I quant.py saida.raw final.png <cores> [1 para dithering]`. O topo "Ao vivo" tem foto, então foi reduzido para 900 px de largura. Use sempre as versões leves nos e-mails.

### Fechamento: tudo leve

Todos os arquivos `*-leve.*` são os que entram nos e-mails: `header-leve.png` (logo, 6 KB), `strip-leve.png` (faixa de data, 4 KB), `hero-e-hoje-leve.png`, `hero-falta-1h-leve.png` e `hero-ao-vivo-leve.png` (topos de live, ~78 KB cada, 900 px, 80 cores) e `foto-modelo-leve.jpg` (foto-modelo da newsletter, 72 KB; a original tinha 2,4 MB). O `gerador/quant.py` agora preserva 3 níveis de transparência parcial (bordas suaves). Regra para fotos reais: JPEG com 900 px de largura e qualidade 55 a 60. Os arquivos sem `-leve` são só histórico.
