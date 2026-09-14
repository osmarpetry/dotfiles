# dx

Man pages, `--help` e documentação oficial — offline, em cache, **fixados na versão
que cada projeto realmente usa**. Mais um alerta do que saiu de suporte.

```sh
dx man [tool]           # man page, ou o --help em cache se o CLI não tiver man
dx doc <slug>[@ver]     # docs da versão do projeto (ou @latest, ou @3.15.3)
dx doc <slug> --grep P  # busca dentro do doc em cache
dx doc <slug> --path    # só o caminho (é o que os agentes usam)
dx pin <slug> <ver>     # fixa a versão do doc neste projeto (.dx.json)
dx doctor [-q]          # o que este projeto tem fora de suporte
dx ls                   # registry + o que está em cache
dx seed <slug>@<ver>    # pré-baixa doc (para usar depois sem rede)
dx refresh              # job diário (launchd)
```

## As três camadas

**L1 — `dx man`.** Índice de `apropos` (12.5k entradas) mais o `--help` capturado de
todo binário em `/opt/homebrew/bin`, `~/.local/bin`, `~/go/bin`, `~/Library/pnpm` e
`/usr/local/bin` que **não** tem man page — 288 aqui, incluindo `temporal`, `pnpm`,
`uv`, `deno`, `asdf`, `poetry`, `codex`. Sem argumento abre um `fzf` com preview.

**L2 — `dx doc`.** Lê a versão do `package.json`/`.nvmrc`/`pyproject.toml`/`go.mod`,
resolve a referência no repositório de docs e faz um clone raso e esparso (só o
diretório de docs). Nuxt 3.15.3 + Nuxt 4.5.2 juntos ocupam 4,8 MB.

Duas estratégias, na coluna `strategy` do `registry.tsv`:

| | como resolve | precisão |
|---|---|---|
| `tag` | checkout na tag da sua versão | exata |
| `date` | commit na data de release da sua versão | aproximada |

`date` existe porque `vuejs/docs`, `temporalio/documentation`, `tailwindcss.com`,
`TypeScript-Website`, `denoland/docs` e `pnpm.io` **não têm tags**. Para esses, a
coluna `datesrc` aponta o repositório de código cujas tags carregam a data de release
(`temporal` → `temporalio/cli`), e o doc é pinado no commit daquele dia. O `dx doc`
avisa na saída quando usa essa estratégia — não é o doc da sua versão, é o doc como
estava quando sua versão saiu.

**L3 — `dx doctor`.** Cruza as versões do projeto com `endoflife.date` e separa em
URGENTE (fora de suporte) e ATENÇÃO (só patch de segurança). Só considera o que o
**projeto declara** — versão global da máquina é ignorada de propósito, senão todo
projeto Node acusaria o Python do sistema.

## Integração

- **zsh** (`~/.config/dx/dx.zsh`): hook de `chpwd` que imprime o aviso ao entrar num
  projeto. Lê um cache de 16 ms; quando o cache está velho recalcula em background e
  mostra na próxima vez. O prompt nunca espera.
- **launchd** (`dev.osmar.dx-refresh`, 09:30 diário): reindexa e atualiza o
  `endoflife.date`. O `--help` de cada CLI é revalidado a cada 7 dias, então só a
  primeira execução é lenta (~3min); as seguintes levam segundos.
- **Claude Code e Codex**: a skill `dx` é instalada nos dois
  (`~/.claude/skills/dx/`, `~/.codex/skills/dx/`) a partir da mesma origem em
  `home/skills/dx/SKILL.md`. Ela manda o agente usar `dx doc --path` antes de
  WebFetch e antes da própria memória.

## Adicionar uma lib

Uma linha em `registry.tsv` (TSV, sete colunas):

```
slug   detect   repo   subdir   strategy   eol   datesrc
```

- `detect`: `npm:<pkg>`, `pypi:<pkg>`, `cmd:<binário>` ou `runtime:node|python|go`
- `eol`: slug em endoflife.date, ou `-` se não houver
- `datesrc`: repositório com as tags de release, ou `-` (só importa para `strategy=date`)

## Testes

```sh
./test.zsh
```

23 asserts sobre as funções puras (`core.zsh`): normalização de range npm, escolha de
tag, veredito de EOL, leitura do registry. Sem rede, sem escrita em disco.

## Sem rede

`dx doc` resolve **do cache primeiro**: se a versão já foi baixada, responde sem
tocar na rede. `dx doctor` cai no `endoflife.date` em cache (80 ms offline).
`dx man` nunca precisou de rede.

`DX_OFFLINE=1` proíbe qualquer acesso à rede. Num cache frio o comando sai com
`exit 3` e diz quais versões existem e qual `dx seed` pedir — em vez de travar
esperando timeout.

Para preparar uma máquina restrita, rode numa com rede e copie `~/.cache/dx`:

```sh
dx seed nuxt@3.15.3 nuxt-ui@2.21.0 vue node python
rsync -a ~/.cache/dx/ maquina-restrita:~/.cache/dx/
```

## PRs ↔ tickets

Genérico — nada aqui é fixo a um org, tracker ou padrão de ticket
específico. `yt` (YouTrack CLI) não tem nenhum link nativo com PR/branch/VCS
— a correlação é feita batendo um padrão de ticket (configurável, ex.
`DEV-123`) contra o branch ou o título do PR.

```sh
# primeira vez num workspace novo — ensina o que esse projeto é
cd ~/workspace/algum-projeto
dx pr init --tracker youtrack --org MinhaOrg \
  --repos repo-a,repo-b,repo-c --ticket-pattern '[A-Z]+-[0-9]+'

dx pr show <owner/repo#N>      # PR + o ticket ligado a ele
dx pr links <owner/repo#N>     # outros PRs abertos ligados ao MESMO ticket
dx pr stack <ticket-ou-PR>     # todo branch, em todo repo configurado, ligado ao ticket
dx pr context <owner/repo#N>   # PR (corpo+comentários+review) + ticket (comentários+relacionados)
dx pr audit [--org O] [--repos r1,r2]
                                # PRs abertos em todos os repos configurados
```

`dx pr init` escreve `.pr-auditor.json` em `$PWD` (achado do mesmo jeito que
`.dx.json` — `dx_find_up`, sobe diretórios até achar). Todo outro `dx pr`
comando lê essa config em vez de assumir um org/tracker fixo; sem config,
`show`/`context` degradam graciosamente (padrão `[A-Z]+-[0-9]+`, tracker
`youtrack`), mas `links`/`stack`/`audit` (que precisam de org+repos pra
buscar) exigem `dx pr init` primeiro.

`dx pr audit`/`dx pr stack` só buscam os dados brutos — priorizar ("isso é
crítico", "isso está parado há uma semana") é julgamento do agente que
consome a saída (persona `pr-auditor`), não lógica fixa aqui.

Exemplo real, testado contra o workspace `~/workspace/deelan/` (três repos
irmãos — frontend, backend, Supabase): `dx pr stack DEV-580` retornou os 9
PRs abertos ligados a esse ticket, todos no repo `deelan` nesse caso
específico; `dx pr context Deelan-AI/deelan#958` trouxe corpo do PR,
comentários, e o ticket YouTrack completo com seus links.

`dx pr show`/`dx pr links` já foram testados contra dados reais do
`Deelan-AI`; a query exata do `yt issues search` pode precisar de ajuste
conforme aparecerem mais casos.

## Cuidados

- O L1 executa `--help` em cada binário sem man page. É execução de código, ainda que
  de binários que você mesmo instalou. Contenção: limite de 6 s via `alarm` do perl,
  `stdin` em `/dev/null`, e a captura roda dentro de um `mktemp -d` descartável —
  alguns binários escrevem no diretório atual mesmo com `--help` (o `patcheck` do
  ffmpeg cria `cvelist` e `patcheck.tmp`). Revise a lista de diretórios em
  `dx_index_build` se ainda incomodar.
- O L2 depende de `gh` autenticado para a estratégia `date` (usa a API de commits).
