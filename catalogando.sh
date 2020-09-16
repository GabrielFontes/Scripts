#! /bin/bash
#
# catalogando.sh - Esse script é responsável por mostrar os usuários responsáveis
# por cada domínio e subdomínio do servidor. E, além disso, a plataforma usada. No
# caso do php, também mostra a versão
#
# O Script guarda:
# Variáveis   |    Conteúdo
#
# "dominio"       os sites presentes no nginx/sites-enabled
# "subdominio"    os subdomínios referentes ao domínio.
# "versaophp"     a versão do php do subdomínio.
#
# Busca nos arquivos                                  Conteúdo                            Salva na variável
# /etc/nginx/sites-enabled                            Domínio                             dominio
# /etc/nginx/sites-enabled/$dominio/$subdominio       Usuário/Versão do php/Plataforma    user/versaophp/magento
# /home[no caso do domínio ser em python e não php]   Usuário                             user
#
# Outras variáveis: redirect, redirect2 no caso de não encontrar a versão do php nem python, o redirect
# guarda para qual site o domínio em questão está sendo redirecionado e no caso de não ter o redirecionamento.
#
#
#
# Por Gabriel Fontes.
#

#
# Seleciona o domínio, subdomínio e busca pela versão do php
#
 for dominio in $(ls /etc/nginx/sites-enabled); do
    for subdominio in $(ls /etc/nginx/sites-enabled/$dominio); do
    versaophp=$(grep "PHPVERSION" /etc/nginx/sites-enabled/$dominio/$subdominio | cut -d ';' -f1 | awk '{print $3}')
#
# Busca pela plataforma e pelo usuário
#
    if [ -n "$versaophp" ]; then
        user=$(grep "USER" /etc/nginx/sites-enabled/$dominio/$subdominio | cut -d ';' -f1 | awk '{print $3}')
        if [ -n "$user" ]; then
            magento=$(grep "magento" /etc/nginx/sites-enabled/$dominio/$subdominio)
            if [ -n "$magento" ]; then
                echo "$dominio, $subdominio, php:$versaophp, $user, magento"
            else
                echo "$dominio, $subdominio, php:$versaophp, $user, wordpress"
            fi
        fi
#
# Caso não encontre a versão do php, busca pelo python e pelo usuário
#
    else
        python=$(grep "proxy" /etc/nginx/sites-enabled/$dominio/$subdominio)
        user=$(find /home -maxdepth 3 -type d -name "$dominio")
        if [ -n "$python" ] && [ -n "$user" ]; then
                user=$(find /home -maxdepth 3 -type d -name "$dominio" | awk -F "/" '{print $3}')
                echo "$dominio, $subdominio, python, $user"
        else
            redirect=$(grep "rewrite" /etc/nginx/sites-enabled/$dominio/$subdominio | awk '{print $3}')
            if [ -n "$redirect" ]; then
                echo "$dominio, $subdominio, redirect:$redirect"
            elif [ -z "$redirect" ]; then
                redirect2=$(grep "return 301" /etc/nginx/sites-enabled/$dominio/$subdominio | awk '{print $3}')
                echo "$dominio, $subdominio, redirect:$redirect2"
            fi
        fi
    fi
    done
  done
