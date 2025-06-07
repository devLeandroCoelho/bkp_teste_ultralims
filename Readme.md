# ✅ Backup Automatizado e Seguro de MySQL em Linux

## 🎯 Objetivo
Este projeto tem como objetivo realizar o backup completo e automatizado de todas as bases de dados MySQL em um ambiente Linux (Ubuntu Server 22.04), seguindo boas práticas de segurança, rotação de backups, agendamento e logging.

## 📁 Estrutura do Projeto
```shell
├── mysql_backup.sh                 # Script principal de backup
├── /var/backups/mysql/            # Diretório onde os backups são salvos
│   ├── teste_backup/              # Para testar o ambiente, criei 2 bancos (teste_backup e app_ultralims)
│   │   ├── teste_backup-20250606-0300.sql.gz
│   ├── app_ultralims/
│   │   ├── app_ultralims-20250606-0300.sql.gz
├── /var/log/mysql_backup.log      # Log das execuções
└── /etc/logrotate.d/mysql_backup  # Configuração de rotação de log
```

## 🧲 Parte 1 – Script de Backup MySQL

🔧 Script: mysql_backup.sh

Realiza backup completo de todos os bancos (exceto os internos).
Gera um arquivo .sql.gz por banco com timestamp.
Mantém apenas os 7 backups mais recentes por banco.
Registra logs com data/hora e status (sucesso ou falha).

```bash
#!/bin/bash

# Ajustar PATH manualmente (para o cron carregar o ambiente)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Diretorio base para os backups
BACKUP_DIR="/var/backups/mysql"

#Data Atual no formato YYYYMMDD-HHMM
DATE=$(date +%Y%m%d-%H%M)

# Quantidade de Backups deve manter
MAX_BACKUPS=7

#Arquivo de LOG
LOG_FILE="/var/log/mysql_backup.log"

# Lista de bancos (menos os padroes)
DATABASES=$(mysql --defaults-file=/home/backupuser/.my.cnf -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

for DB in $DATABASES; do
    DB_DIR="$BACKUP_DIR/$DB"
    mkdir -p "$DB_DIR"

    BACKUP_FILE="$DB_DIR/${DB}-${DATE}.sql.gz"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Realizando backup do banco: $DB"

    #Dump, tratamento de erro e Compactacao
    if mysqldump --defaults-file=/home/backupuser/.my.cnf "$DB" | gzip > "$BACKUP_FILE"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - OK - BACKUP salvo em: $BACKUP_FILE" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERRO - Erro ao fazer o backup do banco: $DB" >> "$LOG_FILE"
        rm -f "$BACKUP_FILE"
        continue
    fi

    # Rotacao: manter apenas os mais recentes (configurado em MAX_BACKUPS)
    find "$DB_DIR" -name "*.sql.gz" | sort -r | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f
done
```

### 📜 Exemplo de log:
```bash
2025-06-06 21:22:15 - Realizando backup do banco: meubanco
2025-06-06 21:22:15 - OK - BACKUP salvo em: /var/backups/mysql/meubanco/meubanco-20250606-0300.sql.gz
```

### ♻️ Rotação de Logs com logrotate

📄 Arquivo: /etc/logrotate.d/mysql_backup

```bash
/var/log/mysql_backup.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 640 root root
}

```
Para testar manualmente:
```bash
sudo logrotate -f /etc/logrotate.d/mysql_backup
```
## ⏰ Parte 2 – Automação com cron

🕒 Agendamento diário

Backup agendado todos os dias às 03:00 AM via cron:
```
sudo crontab -e
```

Adicionado:
```
0 3 * * * sudo -u backupuser /home/backupuser/mysql_backup.sh >> /var/log/mysql_backup.log 2>&1
```

## 🔐 Parte 3 – Segurança e Acesso

👤 Usuário do Sistema
```bash
sudo adduser --disabled-password --gecos "" backupuser
sudo usermod -s /usr/sbin/nologin backupuser
sudo chown -R backupuser:backupuser /var/backups/mysql
```
👤 Usuário MySQL
```sql
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'SENHA_SEGURA';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT ON *.* TO 'backup_user'@'localhost';
FLUSH PRIVILEGES;
```

🔐 Arquivo .my.cnf (seguro)

# /home/backupuser/.my.cnf
```bash
[client]
user=backup_user
password=SENHA_SEGURA
```

```bash
sudo chown backupuser:backupuser /home/backupuser/.my.cnf
sudo chmod 600 /home/backupuser/.my.cnf
```


## 🧐 Parte 4 – Perguntas Conceituais

### 1. Qual a diferença entre backup lógico e físico?

**Lógico** (mysqldump): Exporta os dados em formato SQL legível por humanos. 

* **Vantagens:**
  * Mais portável e simples;
  * Mais facil de verificar integridade dos dados;
  * Permite restaurar em diferentes plataformas e versões do banco de dados
* **Desvantagem:**
  * Mais lento para restaurar grandes bancos.

**Físico** (xtrabackup, cold copy): Cópia binária dos arquivos do banco. 

* **Vantagens:**
  * Mais rápido para restaurar;
  * Ideal para recuperação de desastres e proteção contra corrupção de dados.
* **Desvantagem:**
  * Mais dificil verificar integridade de dados.

### 2. O que deve ser feito antes de restaurar um banco de produção?

* Verificar integridade do backup.
* Validar ambiente de destino (versão compatível, permissões, espaço).
* Realizar testes prévios em ambiente de homologação.
* Notificar stakeholders e planejar janelas de manutenção.

### 3. Como garantir a integridade de backups com alto volume de transações?

Quando estamos lidando com sistemas que mudam muitas informações o tempo todo, é muito importante garantir que os backups sejam feitos da forma certa, sem perder nada.

Para isso, algumas etapas ajudam:

* Antes de começar: Verificar se os arquivos estão em ordem e funcionando bem. Assim, evita salvar algo que já está com problema.

* Durante o envio dos dados: É importante garantir que os arquivos cheguem ao local do backup sem erros. Existem formas de conferir se tudo foi enviado certinho, sem corromper os dados no caminho.

* Depois que o backup termina: Compare o que foi salvo com os arquivos originais para ter certeza de que nada foi perdido ou alterado.

Além disso, usar ferramentas que registram todas as mudanças feitas nos dados (backup transacional) pode ajudar muito. Isso permite restaurar informações com mais precisão, se for necessário.

### 4. Qual o risco de usar root no backup? Como mitigar?

O Risco de usar root no backup é que o uso do root dá acesso total ao sistema, o que aumenta os riscos de falhas críticas, ataques e perda de dados caso o processo seja comprometido.
Como mitigar, criar um usuário específico com permissões limitadas, usar sudo apenas quando necessário e manter logs e auditoria das ações.
