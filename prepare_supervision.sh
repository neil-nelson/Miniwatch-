#!/bin/bash
erreur(){
	echo "Erreur : $1" >&2
	exit 1
}
REP=$(pwd )
if [ "$REP" = "/" ] || [ "REP" = "$HOME" ] ;then
	erreur "ne pas lancer ce script dans / ou dans \$HOME :$REP"
fi

mkdir -p donnees zone_nettoyage/sous_dossier rapports historique logs

JOURNAL=donnees/application.log
:> "$JOURNAL"

for i in $(seq 1  30); do
	case $((i % 4)) in
		0) service=api ;;
		1) service=database ;;
		2) service=auth ;;
		3) service=web ;;
	esac

	case $((i % 5)) in
		0) niveau=ERROR ; message="echec de connexion";;
		3) niveau=WARNING ; message="reponse lente";;
		*) niveau=INFO ; message="requete traitee";;
	esac

	heure="09:$(printf  '%02d' "$i"):00"
	echo "2026-10-13 $heure| $niveau | $service | $message" >> "$JOURNAL"
done

echo "2026-10-13 09:31:00 |INFO |api" >>"$JOURNAL"
echo "2026-10-13 09:32:00 | ERROR | auth | refus en trop | extra " >> "$JOURNAL"
echo "" >> "$JOURNAL"

for j in 1 3 8 15 30  90 ; do
	echo "fichier de $j jours" > "zone_nettoyage/fichier_${j}j.txt"
	touch -d "$j days ago" "zone_nettoyage/fichier_${j}j.txt"
done

echo "rapport ancien" > "zone_nettoyage/rapport ancien.txt"
touch -d "40 days ago" "zone_nettoyage/rapport ancien.txt"

echo "cache" > zone_nettoyage/.cache 
touch -d "20 days ago" zone_nettoyage/.cache

echo "vieux log" > zone_nettoyage/sous_dossier/vieux.log
touch -d "60 days ago" zone_nettoyage/sous_dossier/vieux.log

ln -sf ../donnees/application.log zone_nettoyage/lien_journal
touch -h -d "100 days ago" zone_nettoyage/lien_journal

NB_LIGNES=$(wc -l < "$JOURNAL")
NB_FICHIERS=$(find zone_nettoyage  -type f | wc -l)
NB_LIENS=$(find zone_nettoyage -type l | wc -l)
echo "journal : $NB_LIGNES lignes"
echo "Zone de nettoge : $NB_FICHIERS fichiers et $NB_LIENS lien "
