{\rtf1\ansi\ansicpg1252\cocoartf2822
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 .AppleSystemUIFontMonospaced-Regular;}
{\colortbl;\red255\green255\blue255;\red127\green134\blue144;\red29\green33\blue41;\red199\green206\blue217;
\red238\green88\blue85;\red134\green196\blue255;\red236\green244\blue251;\red91\green165\blue255;}
{\*\expandedcolortbl;;\cssrgb\c56863\c59608\c63137;\cssrgb\c14902\c17255\c21176;\cssrgb\c81961\c84314\c87843;
\cssrgb\c95686\c43922\c40392;\cssrgb\c58824\c81569\c100000;\cssrgb\c94118\c96471\c98824;\cssrgb\c42353\c71373\c100000;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs27\fsmilli13600 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 #!/bin/bash\cf4 \strokec4 \
\
\cf2 \strokec2 # Ajustar PATH manualmente (para o cron carregar o ambiente)\cf4 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf5 \strokec5 export\cf4 \strokec4  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\
\
\pard\pardeftab720\partightenfactor0
\cf2 \strokec2 # Diretorio base para os backups\cf4 \strokec4 \
BACKUP_DIR=\cf6 \strokec6 "/var/backups/mysql"\cf4 \strokec4 \
\
\cf2 \strokec2 #Data Atual no formato YYYYMMDD-HHMM\cf4 \strokec4 \
DATE=\cf6 \strokec6 $(date +%Y%m%d-%H%M)\cf4 \strokec4 \
\
\cf2 \strokec2 # Quantidade de Backups deve manter\cf4 \strokec4 \
MAX_BACKUPS=7\
\
\cf2 \strokec2 #Arquivo de LOG\cf4 \strokec4 \
LOG_FILE=\cf6 \strokec6 "/var/log/mysql_backup.log"\cf4 \strokec4 \
\
\cf2 \strokec2 # Lista de bancos (menos os padroes)\cf4 \strokec4 \
DATABASES=\cf6 \strokec6 $(mysql --defaults-file=/home/backupuser/.my.cnf -e "SHOW DATABASES;" \cf5 \strokec5 |\cf6 \strokec6  grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")\cf4 \strokec4 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \strokec5 for\cf4 \strokec4  \cf7 \strokec7 DB\cf4 \strokec4  \cf5 \strokec5 in\cf4 \strokec4  \cf7 \strokec7 $DATABASES\cf5 \strokec5 ;\cf4 \strokec4  \cf5 \strokec5 do\cf4 \strokec4 \
    DB_DIR=\cf6 \strokec6 "\cf7 \strokec7 $BACKUP_DIR\cf6 \strokec6 /\cf7 \strokec7 $DB\cf6 \strokec6 "\cf4 \strokec4 \
    mkdir -p \cf6 \strokec6 "\cf7 \strokec7 $DB_DIR\cf6 \strokec6 "\cf4 \strokec4 \
\
    BACKUP_FILE=\cf6 \strokec6 "\cf7 \strokec7 $DB_DIR\cf6 \strokec6 /\cf7 \strokec7 $\{DB\}\cf6 \strokec6 -\cf7 \strokec7 $\{DATE\}\cf6 \strokec6 .sql.gz"\cf4 \strokec4 \
    \cf8 \strokec8 echo\cf4 \strokec4  \cf6 \strokec6 "$(date '+%Y-%m-%d %H:%M:%S') - Realizando backup do banco: \cf7 \strokec7 $DB\cf6 \strokec6 "\cf4 \strokec4 \
\
    \cf2 \strokec2 #Dump, tratamento de erro e Compactacao\cf4 \strokec4 \
    \cf5 \strokec5 if\cf4 \strokec4  mysqldump --defaults-file=/home/backupuser/.my.cnf \cf6 \strokec6 "\cf7 \strokec7 $DB\cf6 \strokec6 "\cf4 \strokec4  \cf5 \strokec5 |\cf4 \strokec4  gzip \cf5 \strokec5 >\cf4 \strokec4  \cf6 \strokec6 "\cf7 \strokec7 $BACKUP_FILE\cf6 \strokec6 "\cf5 \strokec5 ;\cf4 \strokec4  \cf5 \strokec5 then\cf4 \strokec4 \
        \cf8 \strokec8 echo\cf4 \strokec4  \cf6 \strokec6 "$(date '+%Y-%m-%d %H:%M:%S') - OK - BACKUP salvo em: \cf7 \strokec7 $BACKUP_FILE\cf6 \strokec6 "\cf4 \strokec4  \cf5 \strokec5 >>\cf4 \strokec4  \cf6 \strokec6 "\cf7 \strokec7 $LOG_FILE\cf6 \strokec6 "\cf4 \strokec4 \
    \cf5 \strokec5 else\cf4 \strokec4 \
        \cf8 \strokec8 echo\cf4 \strokec4  \cf6 \strokec6 "$(date '+%Y-%m-%d %H:%M:%S') - ERRO - Erro ao fazer o backup do banco: \cf7 \strokec7 $DB\cf6 \strokec6 "\cf4 \strokec4  \cf5 \strokec5 >>\cf4 \strokec4  \cf6 \strokec6 "\cf7 \strokec7 $LOG_FILE\cf6 \strokec6 "\cf4 \strokec4 \
        rm -f \cf6 \strokec6 "\cf7 \strokec7 $BACKUP_FILE\cf6 \strokec6 "\cf4 \strokec4 \
        \cf5 \strokec5 continue\cf4 \strokec4 \
    \cf5 \strokec5 fi\cf4 \strokec4 \
\
    \cf2 \strokec2 # Rotacao: manter apenas os mais recentes (configurado em MAX_BACKUPS)\cf4 \strokec4 \
    find \cf6 \strokec6 "\cf7 \strokec7 $DB_DIR\cf6 \strokec6 "\cf4 \strokec4  -name \cf6 \strokec6 "*.sql.gz"\cf4 \strokec4  \cf5 \strokec5 |\cf4 \strokec4  sort -r \cf5 \strokec5 |\cf4 \strokec4  tail -n +\cf6 \strokec6 $((MAX_BACKUPS \cf5 \strokec5 +\cf6 \strokec6  \cf8 \strokec8 1\cf6 \strokec6 ))\cf4 \strokec4  \cf5 \strokec5 |\cf4 \strokec4  xargs -r rm -f\
\cf5 \strokec5 done}