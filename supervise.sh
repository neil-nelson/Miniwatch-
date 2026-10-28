#!/bin/bash

CONF="miniwatch.conf"
RAPPORTS="rapports"
HISTO="historique/mesures.csv"
LOG="logs/miniwatch.log"

#etape1: identité de la machine

echo "MACHINE     :$(hostname)"
echo "UTILISATEUR  :$(whoami)"
echo "DATE         :$(date '+%F %T')"
echo "DEMARRAGE    :$(uptime -p)"
echo "CHARGE       :$(cut -d' ' -f1-3 /proc/loadavg) (1 ,5 , 15 min) "
echo "NOYAU        :$(uname -r)"

#etape2:calcul de la  memoire et disque 

MEMOIRE=$(free | awk '/^Mem:/ {printf "%d", $3 * 100 / $2}')
DISQUE=$(df -P / | awk 'NR == 2 {print $5}' | tr -d '%')

#etape3: seuils et états
erreur() {
 echo "Erreur : $1">&2
 exit 3
}
usage(){
	echo "Usage : $0 [-o REPERTOIRE_RAPPORTS] [-c FICHIER_CONFIG]"
}

if [ -f "$CONF" ]; then
 source "$CONF"
else
  erreur "fichier de configuration introuvable : $CONF"
 
fi

for v in "$DISQUE_WARNING" "$DISQUE_CRITICAL" \
	"$MEMOIRE_WARNING" "$MEMOIRE_CRITICAL"; do
	if ! [[ "$v" =~ ^[0-9]+$ ]]; then
		erreur "seuil non entier : $v "
	fi
done


if [ "$DISQUE_CRITICAL" -lt "$DISQUE_WARNING" ]; then
	erreur "DISQUE_CRITICAL ($DISQUE_CRITICAL) < DISQUE_WARNING ($DISQUE_WARNING)"
fi

if [ "$MEMOIRE_CRITICAL" -lt "$MEMOIRE_WARNING" ]; then
	erreur "MEMOIRE_CRITICAL ($MEMOIRE_CRITICAL) < MEMOIRE_WARNING ($MEMOIRE_WARNING)"
fi

etat(){
	if [ "$1" -ge "$3" ]; then
		echo " [CRITICAL]"
	elif [ "$1" -ge "$2" ]; then
		echo "[WARNING]"
	else
		echo "[OK]"
	fi
}
ETAT_MEMOIRE=$(etat "$MEMOIRE" "$MEMOIRE_WARNING" "$MEMOIRE_CRITICAL")
ETAT_DISQUE=$(etat  "$DISQUE"  "$DISQUE_WARNING"  "$DISQUE_CRITICAL")

echo "Memoire    :$MEMOIRE % $ETAT_MEMOIRE"
echo "Disque /   :$DISQUE  % $ETAT_DISQUE"

