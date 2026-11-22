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
