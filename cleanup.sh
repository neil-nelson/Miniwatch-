#!/bin/bash
erreur() {
    echo "Erreur : $1" >&2
    exit 2
}
ZONE=""
AGE=""
SUPPRESSION=0
while getopts "d:a:x" opt; do
    case $opt in
        d) ZONE="$OPTARG" ;;
        a) AGE="$OPTARG" ;;
        x) SUPPRESSION=1 ;;
        *) echo "Usage: $0 -d répertoire -a jours [-x]" >&2; exit 2 ;;
    esac
done
if [ -z "$ZONE" ] || [ -z "$AGE" ]; then
    echo "Erreur : options -d et -a obligatoires" >&2
    exit 2
fi
if ! [[ "$AGE" =~ ^[0-9]+$ ]]; then
    echo "Erreur le nombre de jours doit être un entier positif" >&2
    exit 2
fi
if [ ! -d "$ZONE" ]; then
    echo "Erreur : le répertoire $ZONE n'existe pas" >&2
    exit 2
fi
CHEMIN=$(realpath "$ZONE" 2>/dev/null)

case "$CHEMIN" in
    */zone_nettoyage) ;;
    *) echo "Erreur chemin interdit $CHEMIN" >&2; exit 2 ;;
esac
mkdir -p logs
FORMAT='%TY-%m-%d %5s octets %P\n'

if [ "$SUPPRESSION" -eq 0 ]; then
    echo "SIMULATION fichiers de plus de $AGE jours:"
    find "$CHEMIN" -type f -mtime "+$AGE" -printf "$FORMAT" | sort
    
    nb=$(find "$CHEMIN" -type f -mtime "+$AGE" | wc -l)
    echo "$nb fichiers seraient supprimés (ajouter -x pour supprimer)"

else
    fichiers=$(find "$CHEMIN" -type f -mtime "+$AGE")
    nb=0
    
    if [ -n "$fichiers" ]; then
        while read -r f; do
            [ -z "$f" ] && continue
            nom=$(basename "$f")
            
            rm -f -- "$f"
            echo "Supprimé $nom"
           
            echo "$(date '+%F %T') | Supprimé | $f" >> logs/cleanup.log
            nb=$((nb + 1))
        done <<< "$fichiers"
    fi
    echo "$nb fichiers supprimés (voir logs/cleanup.log)"
fi
