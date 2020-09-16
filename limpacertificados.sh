#!/bin/bash
#
# limpacertificados.sh - Remove os certificados que por algum motivo não conseguiram
# ser renovados.
#
# passos:
#
# - Excluir os domínios/subdomínio do ngnix/sites-enabled
# - Excluir os certificados em etc/letsencrypt/live/subdomínio+domínio/
# - certbot revoke --cert-path etc/letsencrypt/live/subdomínio+domínio/fullchain.pem
# - certbot delete
#
# O Script executa o comando certbot renew direcionando a saída para um arquivo
# /root/teste.txt. Depois, filtra e separa os relatórios disponibilizados pelo Let's
# Encrypt em /root/teste1.txt:
#
#   Domain: xxxx - Nome do domínio (Subdomínio+Domínio)
#   Type: xxx - Qual foi o tipo de erro
#
# Busca no ngnix os domínios/subdomínios, exclui os diretórios do ngnix. E executa 'certbot 
# delete', busca o número do subdomínio+domínio e deleta o certificado.
#
# Versão 0 :
#
# Por Gabriel Fontes.
#

#
# Lista em um arquivo <teste1.txt> os domínios que não tiveram os certificados renovados e os tipos de erro
#
certbot renew>/root/teste.txt
grep -E "Domain|Type" teste.txt>teste1.txt
rm teste.txt

#
# Faz o tratamento das url's do arquivo teste1.txt.
#
for dominio_aux in $(cat teste1.txt | grep "Domain"| awk -F ":" '{print $2}'); do
    dominio_aux2=$(echo "$dominio_aux" | awk -F "." '{print $2}')
    subdominio_aux2=$(echo "$dominio_aux" | awk -F "." '{print $1}')
    echo "dominio_aux2:$dominio_aux2 e subdominio_aux2: $dominio_aux2 "
    if [ "$dominio_aux2" != "$subdominio_aux2" ]; then
        dominio=$(echo "$dominio_aux" | awk -F "." '{print $2}')
        subdominio=$(echo "$dominio_aux" | awk -F "." '{print $1}')
        nginx_dominio=$(find /etc/nginx/sites-enabled/ -maxdepth 1 -type d -name "$dominio".*)
        if [ -n "$nginx_dominio" ]; then
            nginx_subdominio=$(find /etc/nginx/sites-enabled/"$dominio".* -maxdepth 2 -name "$subdominio" )
        else
            dominio=$(echo "$dominio_aux" | awk -F "." '{print $1}')
            nginx_dominio=$(find /etc/nginx/sites-enabled/ -maxdepth 1 -type d -name "$dominio".*)
        fi
    fi
    echo "dominio: $dominio , Subdominio : $subdominio"
done

#
# Testa a existência do dominio e do subdominio e caso exista, solicita uma confirmação de exclusão do diretório no nginx.
#
if [ -n "$nginx_dominio" ]; then
        echo "$dominio existe."
    if [ -n "$nginx_subdominio" ]; then
        read -p "Tem certeza que quer excluir o dominio: $dominio.*.$subdominio? (1)Sim (2)Não" var_aux1
        if [ "$var_aux1" -eq 1 ]; then
            #rm -rf /etc/ngnix/sites-enabled/$dominio.*/$subominio
            echo "$subdominio existe e a pasta /nginx/sites-enabled/$dominio/$subominio foi excluída."
#
# Exclui o certificado
#
            #certbot revoke --cert-path /etc/letsencrypt/live/$subdominio.$dominio*/fullchain.pem
        else
            echo "$subdominio existe e a pasta /nginx/sites-enabled/$dominio/$subominio não foi excluída."
        fi
#
# Para casos com mais de um subdominio
#
    else
        ls /etc/nginx/sites-enabled/"$dominio".*>/root/subdominios.txt
        while read linha
        do
            let i++
            nginx_subdominio=( ${nginx_subdominio[@]} "$linha")
        done < /root/subdominios.txt
        echo -e "O domínio $dominio contém os subdomínios: ${nginx_subdominio[@]} \n"
        read -p "Deseja excluir o certificado de algum deles? (1)sim (2)não" var_aux2
        if [ $var_aux2 -eq 1 ]; then
            read -p "Qual deles?" subdominio
            #rm -rf /etc/nginx/sites-enabled/$dominio.*/$subdominio
#
# Exclui o certificado
#
            #certbot revoke --cert-path /etc/letsencrypt/live/$subdominio.$dominio*/fullchain.pem
        fi
    fi
else
    echo "$dominio não existe"
fi
