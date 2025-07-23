# 🛠️ Instalador de Serviços Java para Windows

<p align="center">
  <img src="https://img.shields.io/badge/Inno%20Setup-v6.2.2-blue?logo=inno-setup" />
  <img src="https://img.shields.io/badge/NSSM-Service_Manager-lightgrey" />
  <img src="https://img.shields.io/badge/Java-17%2B-orange?logo=java" />
  <img src="https://img.shields.io/badge/PostgreSQL-14%2F16-blue?logo=postgresql" />
  <img src="https://img.shields.io/badge/Windows-64--bit-lightblue?logo=windows" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>


## Pré-requisitos

Antes de executar o instalador, certifique-se de que:

- [x] Java 17+ esteja instalado
- [x] A variável de ambiente `JAVA_HOME` esteja corretamente configurada
- [x] PostgreSQL 14 ou 16 esteja presente no sistema
- [x] Você esteja usando **Windows 64 bits**
- [x] Possua privilégios de administrador para instalação

---

## Gerando o Instalador

1. Instale o [Inno Setup](https://jrsoftware.org/isdl.php)
2. Abra o arquivo `template.iss`
3. Compile com `F9` ou vá em `Build > Compile`
4. O instalador será gerado na raiz do projeto

---

## Instalação

Execute instalador como administrador.

Durante a instalação:

- O `.jar` será copiado para `C:\Program Files\nomeDoApp`
- O serviço será registrado via `nssm`
- Logs padrão (`stdout.log` e `stderr.log`) serão gerados em `C:\Program Files\nomeDoApp\logs`
- O serviço será iniciado automaticamente

---

## Atualizando o JAR

Para atualizar sua aplicação:

```bash
nssm stop nomeDoServiço        # Para o serviço
# Substitua o .jar manualmente em C:\Program Files\nomeDoApp
nssm start nomeDoServico        # Reinicie o serviço

---

## Remover/desinstalar a aplicação:

- Acesse o diretório onde a aplicação foi instalada (ex: C:\Program Files\nomeDoApp)

- Execute o Uninstaller (unins*.exe) como administrador

- O serviço será parado, removido e os arquivos apagados automaticamente