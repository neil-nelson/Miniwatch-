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


while getopts "o:c:" option; do
 case "$option" in
  o) RAPPORTS="$OPTARG" ;;
 c) CONF="$OPTARG" ;;
  *) exit 3 ;;
esac
done

mkdir -p "$RAPPORTS" 2>/dev/null || erreur "Répertoire inaccessible : $RAPPORTS"

[ -d "$RAPPORTS" ] && [ -w "$RAPPORTS" ] || erreur "Répertoire inaccessible : $RAPPORTS"


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
		echo "[CRITICAL]"
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

#etape5 : rapport,état global et de retour
CODE=0
for e in "$ETAT_MEMOIRE" "$ETAT_DISQUE";do
 if [ "$e" = "[CRITICAL]" ]; then
  CODE=2
 elif [ "$e" = "[WARNING]" ] && [ "$CODE" -lt  1 ]; then
  CODE=1
 fi
done
case "$CODE" in
 0) GLOBAL=OK ;;
 1) GLOBAL=WARNING ;;
 2) GLOBAL=CRITICAL ;;
esac

echo "Etat global  :$GLOBAL"

RAPPORT="$RAPPORTS/rapport_$(date +%Y%m%d_%H%M%S).txt"

{
 echo "======= RAPPORT MINIWATCH ====="
 echo "Machine      :$(hostname)"
 echo "UTILISATEUR  :$(whoami)"
 echo "DATE         :$(date '+%F %T')"
 echo "DEMARRAGE    :$(uptime -p)"
 echo "CHARGE       :$(cut -d' ' -f1-3 /proc/loadavg) (1 ,5 , 15 min) "
 echo "NOYAU        :$(uname -r)"
 df -hP
 ps -eo pid,user,comm,%cpu --sort=-%cpu | head -n 4
 ps -eo pid,user,comm,%mem --sort=-%mem | head -n 4
 ip -4 -o addr show | awk '{print $2, $4}'
 echo "Etat global  :$GLOBAL"
}> "$RAPPORT"

echo "Rapport       :$RAPPORT"
echo "$(date '+%F %T') | etat=$GLOBAL | memoire=$MEMOIRE | disque=$DISQUE" >> "$LOG"


#etape6:historique csv et statistiques
if [ ! -f "$HISTO" ]; then
 echo "date;machine;memoire_pct;disque_racine_pct;charge1;etat"> "$HISTO"
fi
echo "$(date '+%F %T');$MACHINE;$MEMOIRE;$DISQUE;$CHARGE;$GLOBAL" >> "$HISTO"
exit "$CODE"
