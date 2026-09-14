---
name: dx
description: Consulta documentação local em cache, fixada na versão que o projeto realmente usa, e checa o que saiu de suporte. Use SEMPRE antes de escrever ou revisar código que toca Nuxt, Vue, Nuxt UI, Vite, Pinia, Tailwind, TypeScript, Temporal, Supabase, Node, Python, Go, uv ou pnpm — e antes de usar WebFetch/WebSearch para docs dessas libs. Também use quando o usuário perguntar "qual a flag de X", "como usa Y nesta versão", "posso atualizar Z", "isso ainda tem suporte", ou pedir a man page / --help de qualquer CLI da máquina.
---

# dx — docs offline, na versão do projeto

`dx` mantém em `~/.cache/dx` as man pages, o `--help` de todo CLI da máquina, e os
docs oficiais **no commit/tag da versão que este projeto usa**. Tudo local.

**Regra:** para as libs do registry, `dx` vem antes de WebFetch, WebSearch e antes
da sua própria memória. Sua memória é da versão errada com frequência — o cache não.

## Antes de escrever código

```bash
dx doctor                       # o que este projeto tem fora de suporte
dx doc nuxt --path              # caminho do doc DA VERSÃO DO PROJETO
dx doc nuxt --grep 'useFetch'   # busca dentro dele, offline
```

`dx doc <slug> --path` imprime um diretório. Leia os `.md` de lá com Read/Grep como
qualquer arquivo do repositório. Cite o arquivo do cache ao afirmar algo sobre a API.

## Comparar versões (para migração)

```bash
dx doc nuxt            # a versão que o projeto usa hoje
dx doc nuxt@latest     # a versão nova
dx doc nuxt@3.21.11    # uma versão específica
```

Para avaliar um upgrade, leia os dois e compare — não deduza o diff de cabeça.

## Slugs

`dx ls` lista o registry. Hoje: `nuxt`, `nuxt-ui`, `vue`, `vite`, `pinia`,
`typescript`, `tailwind`, `temporal`, `temporal-py`, `temporal-ts`, `supabase`,
`node`, `python`, `go`, `deno`, `uv`, `pnpm`.

Se a lib não estiver no registry, aí sim WebFetch — e sugira ao usuário adicioná-la
em `~/dotfiles/dx/registry.tsv`.

## CLIs

```bash
dx man temporal    # man page, ou o --help em cache se o CLI não tiver man
```

288 CLIs da máquina não têm man page (temporal, pnpm, uv, deno, asdf, poetry, codex…).
`dx man` cobre os dois casos, então use-o em vez de rodar `--help` você mesmo.

## Precisão da versão

Duas estratégias, e a diferença importa quando você cita uma API:

- **`tag`** (nuxt, nuxt-ui, vite, pinia, node, python, go, uv, supabase, temporal-py/ts)
  — checkout na tag exata. O doc **é** o da sua versão.
- **`date`** (vue, temporal, tailwind, typescript, deno, pnpm) — o repo de docs não
  tem tags, então `dx` pina no commit da data de release da sua versão. É uma
  **aproximação**: trate como "o doc como estava quando sua versão saiu", não como
  garantia. `dx doc` avisa na saída quando usa essa estratégia.

Se um comportamento documentado parecer inconsistente com o código do projeto,
suspeite da aproximação `date` antes de suspeitar do código.

## Ao relatar um upgrade

`dx doctor` separa em URGENTE (fora de suporte) e ATENÇÃO (só patch de segurança).
Ao trazer isso ao usuário, diga a versão atual, a data em que o suporte acabou, e
onde está o guia de migração no doc em cache — não só "está desatualizado".

## Sem rede

`dx doc` responde do cache sem tocar na rede quando a versão já foi baixada.
Com `DX_OFFLINE=1` e cache frio, o comando sai com `exit 3` e lista o que existe.
Nesse caso **pergunte ao usuário** — não caia para a memória nem deduza a API do
código ao redor.

## Revisão de PR (tracker + GitHub)

Sem config nenhuma é fixa — primeiro uso num workspace novo pede pra
configurar (`dx pr init`), não assume org/tracker/padrão de ticket.

```bash
dx pr init --tracker youtrack --org O --repos r1,r2,r3 --ticket-pattern 'X'
                                # uma vez por workspace (achado via dx_find_up,
                                # igual .dx.json — sobe diretórios até achar)

dx pr show <owner/repo#N>      # o PR + o ticket ligado a ele
dx pr links <owner/repo#N>     # ANTES de aprovar: outros PRs abertos no MESMO ticket
dx pr stack <ticket-ou-PR>     # todo branch, em todo repo, ligado a um ticket —
                                # o que trazer junto pra rodar um projeto full-stack local
dx pr context <owner/repo#N>   # corpo+comentários do PR (discussão e review inline) +
                                # ticket+comentários+relacionados — pra escrever
                                # descrição, plano de teste, ou revisar um PR de colega
dx pr audit [--org O]          # visão geral dos PRs abertos nos repos configurados
```

`yt` não liga PR a ticket nativamente — `dx pr` faz essa correlação batendo
o padrão do ticket (default `[A-Z]+-[0-9]+`, configurável) no branch/título.
Rode `dx pr links` antes de aprovar qualquer PR ligado a um ticket: um outro
repo pode ter um PR pendente do mesmo ticket que muda o que "pronto para
aprovar" significa aqui.

Sem `.pr-auditor.json` em nenhum diretório acima do `$PWD`, `show`/`context`
caem pro padrão genérico (`youtrack`, `[A-Z]+-[0-9]+`); `links`/`stack`/`audit`
(que precisam de org+repos) recusam com uma mensagem clara apontando pro
`dx pr init` em vez de adivinhar.

## Limites

- O cache atualiza uma vez por dia via launchd. `dx refresh` força.
- `dx doctor` só olha o que o **projeto declara** (`package.json`, `.nvmrc`,
  `pyproject.toml`, `go.mod`). Versão global da máquina é ignorada de propósito.
- Não invente slug: `dx ls` é a lista real.
