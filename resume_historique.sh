#!/bin/bash

FICHIER="historique/mesures.csv"

tail -n +2 "$FICHIER" | awk -F';' '
{
  n++
  somme += $3
  if (n == 1 || $3 < min) min = $3
  if ($3 > max) max = $3
  if ($6 == "WARNING") w++
  if ($6 == "CRITICAL") c++
  if ($6 == "OK") o++
}
END {
  print "Mesures : " n
  printf "Mémoire : min %d %%- moyenne %.1f %%- max %d %%\n", \
       min, somme / n, max

 print "WARNING     : " w
 print "CRITICAL    : " c
 print "État normal : " o
}'
