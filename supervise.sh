#!/bin/bash

CONF="miniwatch.conf"
RAPPORTS="rapports"
HISTO="historique/mesures.csv"
LOG="logs/miniwatch.log"

erreur(){
	echo "Erreur : $1" >&2
	exit 3
}

usage(){
	echo "Usage : $0 [-o REPERTOIRE_RAPPORTS] [-c FICHIER_CONFIG]"
}

[ -n "$1" ] && CONF="$1"

[ -f "$CONF" ] || erreur "fichier de configuration introuvable : $CONF"
source "$(realpath "$CONF")"

for v in "$DISQUE_WARNING" "$DISQUE_CRITICAL" \
	"$MEMOIRE_WARNING" "$MEMOIRE_CRISTAL"; do
	if ! [[ "$v" =~ ^[0-9]+$ ]]; then
		erreur "seuil non entier : $v"
	fi
done

if [ "$DISQUE_CRITICAL" -lt "$DISQUE_WARNING" ]; then
	erreur "DISQUE_CRITICAL ($DISQUE_CRITICAL) < DISQUE_WARNING ($DISQUE_WARNING)"
fi
if [ "$MEMOIRE_CRITICAL" -lt "$MEMOIRE_WARNING" ]; then
	erreur "MEMOIRE_CRITICAL ($MEMOIRE_CRITICAL) < MEMOIRE_WARNING ($MEMOIRE_WARNING)"
fi



MACHINE=$(hostname)
UTILISATEUR=$(whoami)
DATE=$(date '+%F %T')
DEMARRAGE=$(uptime -p)
CHARGE=$(cut -d' ' -f1-3 /proc/loadavg)
CHARGE1=$(cut -d' ' -f1 /proc/loadavg)
NOYAU=$(uname -r)

MEMOIRE=$(LC_ALL=C free | awk '/^Mem/ {printf "%d", $3 * 100 / $2')
DISQUE=$(LC_ALL=C df -P / | awk 'NR == 2 {printf $5}' | tr -d '%')

[[ "$MEMOIRE" =~ ^[0-9]+$ ]] || erreur "mesure de la memoire impossible"
[[ "$DISQUE" =~ ^[0-9]+$ ]] || erreur "mesure du disque impossible"

etat(){
	if [ "$1" -ge "$3" ]; then
		echo "CRITICAL"
	elif [ "$1" -ge "$2" ]; then
		echo "WARNING"
	else
		echo "OK"
	fi
}

ETAT_MEMOIRE=$(etat "$MEMOIRE"  "$MEMOIRE_WARNING" "$MEMOIRE_CRITICAL")
ETAT_DISQUE=$(etat "$DISQUE" "$DISQUE_WARNING" "$DISQUE_CRITICAL")
