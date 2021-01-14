#!/bin/bash

function installHarvester() {
	sudo apt install -y theHarvester
        if [ $? -ne 0 ];then
             echo "Falha na instalação do theHarvester! Saindo..."
             exit 1
        fi
}

if [ $# -ne 1 ];then
 echo "Sintaxe: $0 dominio_alvo"
 echo " Ex: $0 evilcorp.com"
 exit 1
fi

if ! dpkg -l | grep -i theharvester >/dev/null
then
	echo "TheHarvester não está instalado."
	echo -n "Deseja instalar? (s/N) "
	read RESP
	case $RESP in
	s|S) installHarvester
	;;
	n|N) echo "Saindo..."; exit 1;;	
	*) installHarvester
	;;
	esac
	exit 1
fi

DOMINIO="$1"
LISTATEMP="/tmp/${DOMINIO}.linkedinner.out"
RESULT="${DOMINIO}_users.txt"
> $LISTATEMP

echo "Executando busca no linkedin..."
theHarvester -d $DOMINIO -b linkedin > $LISTATEMP
if [ $? -ne 0 ];then
	echo "Erro ao executar o theHarvester!"
	exit 1
fi

if grep "No users found" $LISTATEMP >/dev/null
then
	echo "Não foram encontrados usuários para o domínio ${DOMINIO}."
	echo "É possível que o google esteja bloqueando nossos requests..."
	echo "Aguarde um tempo ou altere seu IP!"
	exit 1
fi

NUMUSERS=`grep -i 'users found' $LISTATEMP |cut -f4 -d' '`
let NAFTER=$NUMUSERS+1

grep -i -A ${NAFTER} 'users found' $LISTATEMP |grep -i -v -e 'users found' -e '------' -e '^$' -e search \
|cut -f1 -d'-' |tr [A-Z] [a-z] | while read a b c ; 
do 
	echo "${a}.${b}@${DOMINIO}" |tee -a $RESULT; 
	if [ ! -z "$c" ] 
	then
	   	#removendo parte fraca de sobrenomes compostos
		c=`echo "$c" |sed -e 's/dos / /' -e 's/de / /' -e 's/da / /' -e 's/do / /' -e 's/das / /'` 
		echo $c |while read c1 c2 #loop necessario para tratar nomes com quatro partes
		do
			echo "${a}.${c1}@${DOMINIO}" |tee -a $RESULT 
			echo "${b}.${c1}@${DOMINIO}" |tee -a $RESULT
			#Verifica se existe ainda um quarto nome
			if [ ! -z "$c2" ];then
				echo "${a}.${c2}@${DOMINIO}" |tee -a $RESULT 
				echo "${b}.${c2}@${DOMINIO}" |tee -a $RESULT
			fi
		done
	fi
done
NUMFOUND=`cat $RESULT |wc -l`

echo "---------------------------------------------------------- "
echo " Arquivo $RESULT gerado com sucesso! "
echo " Gerados $NUMFOUND usuários possíveis. "
echo "----------------------------------------------------------"
rm -f $LISTATEMP
exit 0
