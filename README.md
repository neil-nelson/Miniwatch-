# MiniWatch — Supervision et maintenance système sous Linux
Outil de supervision et de maintenance Linux développé en Bash.

## 1. Présentation du projet

MiniWatch est un projet développé en Bash dans le cadre du module Linux & Scripts Shell.

Son objectif est d'automatiser plusieurs opérations d'administration système : surveiller l'utilisation des ressources, produire des rapports, conserver un historique des mesures, analyser des journaux et nettoyer des fichiers anciens en toute sécurité.

Le projet est organisé en plusieurs scripts, chacun ayant une responsabilité précise.

## 2. Organisation des fichiers

Le dépôt contient cinq dossiers principaux, cinq scripts Bash, un fichier de configuration principal et quatre fichiers de configuration destinés aux tests.

### Les dossiers

**`donnees/`**

Ce dossier contient les données utilisées pour les tests, notamment les journaux d'application exploités par le script d'analyse des logs.

Il permet de disposer de fichiers sur lesquels effectuer les analyses sans modifier les journaux du système Linux.

**`historique/`**

Ce dossier conserve les mesures enregistrées lors des différentes exécutions du script de supervision.

Le fichier `mesures.csv` permet de retrouver les valeurs précédentes de mémoire et de disque. Ces données sont ensuite exploitées par le script de résumé historique.

**`logs/`**

Ce dossier regroupe les journaux produits par MiniWatch.

Le journal de supervision conserve une trace des exécutions et de leurs résultats. Le journal de nettoyage enregistre les suppressions effectuées.

Ces fichiers permettent de consulter les opérations passées.

**`rapports/`**

Ce dossier accueille les rapports détaillés générés par la supervision.

Chaque rapport contient des informations sur la machine, l'utilisation des ressources, les processus, le réseau et l'état global.

Les rapports sont horodatés afin de distinguer les différentes exécutions.

**`zone_nettoyage/`**

Ce dossier est réservé aux opérations de nettoyage.

Il contient des fichiers de test dont certains sont volontairement anciens. Le script de nettoyage peut ainsi rechercher et supprimer les fichiers concernés sans intervenir dans les autres dossiers du projet.

Cette restriction est une mesure de sécurité essentielle.

---

## 3. Description et utilisation des scripts

### 3.1. `prepare_supervision.sh` — Préparation de l'environnement

Ce script permet d'initialiser l'environnement de MiniWatch.

Il prépare les répertoires et les fichiers nécessaires à l'exécution des différents scripts. Il permet notamment de disposer des données de test utilisées pour l'analyse des journaux et le nettoyage.

Son utilisation est recommandée avant les premiers tests du projet.

**Utilisation :**

`./prepare_supervision.sh`

Après son exécution, les autres scripts disposent de l'environnement nécessaire à leur fonctionnement.

### 3.2. `supervise.sh` — Surveillance du système

Ce script constitue la fonctionnalité principale de MiniWatch.

Il récupère les informations de la machine, mesure l'utilisation de la mémoire et du disque, puis compare ces valeurs aux seuils définis dans le fichier de configuration.

Chaque ressource reçoit un état : OK, WARNING ou CRITICAL.

L'état global est déterminé à partir de l'état le plus grave détecté.

Le script produit ensuite un rapport détaillé dans le dossier `rapports/`, ajoute les mesures dans l'historique et conserve un résumé de l'exécution dans le journal de supervision.

Il vérifie également la validité de la configuration et l'accessibilité du répertoire de destination.

**Utilisation normale :**

`./supervise.sh`

**Pour choisir un autre dossier de rapports :**

`./supervise.sh -o mes_rapports`

**Pour utiliser une autre configuration :**

`./supervise.sh -c test_warning.conf`

**Pour personnaliser les deux paramètres :**

`./supervise.sh -o mes_rapports -c test_critical.conf`

L'option `-o` permet de choisir le répertoire des rapports, tandis que `-c` permet de sélectionner un fichier de configuration.

### 3.3. `resume_historique.sh` — Analyse des mesures enregistrées

Ce script exploite les données collectées par `supervise.sh`.

Son rôle est de lire le fichier historique et d'en extraire les informations nécessaires à la réalisation de statistiques sur les ressources surveillées.

Il permet ainsi d'obtenir une vue d'ensemble des mesures enregistrées lors des exécutions précédentes.

Contrairement au script principal, qui analyse la machine à un instant donné, ce script travaille sur plusieurs mesures déjà collectées.

**Utilisation :**

`./resume_historique.sh`

Il est préférable d'avoir exécuté `supervise.sh` plusieurs fois afin de disposer de données historiques à analyser.

### 3.4. `analyse_logs.sh` — Analyse des journaux d'application

Ce script permet d'examiner les événements enregistrés dans un fichier journal.

Il lit les données du journal, identifie les informations utiles et réalise les analyses et comptages prévus par le projet.

Il facilite ainsi la compréhension du comportement d'une application et l'identification des événements importants, notamment les avertissements et les erreurs.

Les fichiers utilisés pour les tests sont conservés dans le dossier `donnees/`.

**Utilisation :**

Le script s'exécute depuis le terminal. Les paramètres exacts à fournir dépendent des options définies dans sa version finale.

### 3.5. `cleanup.sh` — Nettoyage sécurisé des fichiers

Ce script a été conçu pour rechercher et supprimer les fichiers anciens dans un répertoire strictement autorisé.

Son fonctionnement repose sur deux modes.

**Mode simulation**

Le programme recherche les fichiers correspondant au critère d'ancienneté et affiche leurs informations sans effectuer de suppression.

**Utilisation :**

`./cleanup.sh -d zone_nettoyage -a 7`

Cette commande permet d'identifier les fichiers concernés par le critère d'ancienneté.

**Mode suppression**

L'ajout de l'option `-x` autorise la suppression réelle.

**Utilisation :**

`./cleanup.sh -d zone_nettoyage -a 7 -x`

Chaque suppression est enregistrée dans le journal de nettoyage.

Le script contrôle les paramètres fournis et vérifie le chemin réel du répertoire afin de refuser toute opération en dehors de la zone autorisée.

Il protège ainsi les autres fichiers du projet et les données personnelles de l'utilisateur.

---

## 4. Description des fichiers de configuration

### `miniwatch.conf`

Il s'agit du fichier de configuration principal du système de supervision.

Il contient les seuils d'avertissement et les seuils critiques utilisés pour évaluer la mémoire et le disque.

Ces seuils permettent d'adapter le comportement de la supervision sans modifier directement le script.

### `test_warning.conf`

Ce fichier sert à tester le comportement du programme lorsqu'une ressource atteint un seuil d'avertissement.

Il permet de vérifier que la supervision détecte correctement un état WARNING et le répercute dans le résultat global.

### `test_critical.conf`

Ce fichier est destiné aux tests de situations critiques.

Il permet de vérifier que le programme identifie un état CRITICAL et lui donne la priorité lors du calcul de l'état global.

### `test_faux.conf`

Ce fichier sert à tester la réaction du programme face à une configuration incorrecte.

Il permet notamment de vérifier que les contrôles de validation détectent les paramètres invalides et empêchent la supervision de continuer avec des valeurs incorrectes.

### `test_incoherent.conf`

Ce fichier permet de tester la cohérence des seuils.

Par exemple, un seuil critique inférieur au seuil d'avertissement constitue une configuration incohérente.

Le programme doit détecter cette situation et signaler une erreur plutôt que poursuivre avec des seuils contradictoires.

---

## 5. Ordre conseillé d'utilisation

Pour découvrir et tester MiniWatch, il est recommandé de procéder dans l'ordre suivant :

1. Préparer l'environnement avec `prepare_supervision.sh`.
2. Exécuter `supervise.sh` pour effectuer les premières mesures.
3. Consulter les rapports et l'historique générés.
4. Tester les différents fichiers de configuration pour observer les états et les erreurs.
5. Utiliser `resume_historique.sh` pour analyser les mesures enregistrées.
6. Utiliser `analyse_logs.sh` pour examiner les journaux d'application.
7. Tester `cleanup.sh` en simulation avant d'autoriser une suppression.

Cette progression permet de comprendre le rôle de chaque composant tout en limitant les risques liés aux opérations de maintenance.

## 6. Sécurité et gestion des erreurs

MiniWatch intègre plusieurs mécanismes de contrôle.

Les fichiers de configuration sont vérifiés avant utilisation. Les seuils doivent être valides et cohérents.

Les répertoires de sortie doivent être accessibles afin de permettre l'enregistrement des résultats.

Les opérations de nettoyage sont limitées à une zone dédiée. La suppression n'est jamais effectuée par défaut : elle nécessite une option explicite.

Les journaux conservent une trace des opérations, tandis que les codes de retour permettent d'identifier les situations normales et les erreurs.

## 7. Conclusion

MiniWatch regroupe plusieurs fonctionnalités complémentaires d'administration système dans un projet Bash organisé de manière modulaire.

Chaque script remplit une fonction précise, depuis la préparation de l'environnement jusqu'à la supervision, l'analyse des données et la maintenance des fichiers.

Cette organisation facilite la compréhension du projet, son utilisation et son évolution.

Le projet permet de mettre en pratique la programmation Shell, l'utilisation des commandes Linux, la gestion des fichiers, la supervision système, la validation des paramètres et les principes de sécurité.
