# EkoFest [![Netlify Status](https://api.netlify.com/api/v1/badges/0cfcd65b-b2af-4791-88d1-0d63a30b0553/deploy-status)](https://app.netlify.com/sites/ekofest/deploys)

A lightweight and efficient tool for calculating the carbon footprint of events.

> [!TIP]
> This project is built with [Elm](https://elm-lang.org/) and
> [Publicodes](https://publi.codes/)!

> [!IMPORTANT]
> 🇫🇷 Ekofest website, model and documentation are almost exclusively written in French. Please, raise an issue if you are interested and do not speak French.

## Installation

```bash
yarn install
```

## Usage

```bash
yarn dev
```

## C'est quoi ?

Ekofest est un outil d'aide à la décision : en quelques minutes, les organisateurs de festival peuvent estimer l'empreinte carbone de leur événement afin de repérer les postes les plus émetteurs pour prendre les meilleures décisions pour le climat.

> ⚠️ Ce n'est pas un outil certifié de calcul de Bilan Carbone® : il s'agit d'une estimation simplifiée de l'empreinte carbone d'un festival. Le résultat obtenu ne peut pas être utilisé comme un calcul officiel.

Une interface simple et intuitive permet de renseigner les informations clés de l'événement (nombre de participants, durée, etc.) via 6 catégories :

-   Alimentation
-   Transport
-   Infrastructures
-   Hébergement
-   Énergie
-   Communication

Afin d'afficher un résultat pertinent dès les premières saisies, des valeurs par défaut ont été paramétrées pour chaque entrée. Ces valeurs sont basées sur des données réelles de festivals et permettent d'avoir une première estimation de l'empreinte de l'événement et par festivalier avant d'être ajustées. Enfin, il est possible de partir d'un profil type de festival qui se rapproche de votre évènement.

L'ensemble du modèle de calcul est documenté et [accessible en ligne](https://ekofest.fr/documentation). Toute personne curieuse peut consulter les détails des hypopthèses que nous avoins retenu. Nous sommes évidemment preneurs de [vos retours](#contact-et-retours).

## Pour qui ?

Ekofest s'adresse aux organisateurs de festivals, et a vocation à être utilisé dans la phase amont de l'organisation d'un événement, au moment où il est encore possible de prendre des décisions structurantes pour le festival. L'outil est conçu pour être utilisé par des personnes n'ayant pas de compétences techniques particulières en matière de calcul d'empreinte carbone.

## Par qui ?

Cette première version du site a été developpé, gratuitement, via une collaboration de deux développeurs / experts métiers carbone, Emile et Clément, contributeurs importants du projet [Nos Gestes Climat](http://nosgestesclimat.fr/) de l'ADEME. Certaines données utilisées dans ekofest sont d'ailleurs issues de ce calculateur d'empreinte carbone indviduelle, à l'image de l'empreinte des repas.

## Et côté technique ?

### Développement

Ekofest est un projet open-source, ce qui signifie que tout le monde peut y contribuer.

On distingue deux parties dans le projet, qui se traduisent par deux dépôts Github :

-   Le site web, développé en [ELM](https://elm-lang.org/), un langage de programmation fonctionnel pour le web : https://github.com/ekofest/ekofest.

-   Le modèle de calcul, construit via [Publi.codes](https://publi.codes/), un langage déclaratif pour l'élaboration de modélisations complexes : https://github.com/ekofest/publicodes-evenements.

Le site importe le modèle pour effectuer les calculs via le moteur Publicodes et afficher les résultats.

### Hébergement

Le modèle est déployé sous forme de [paquet NPM](https://www.npmjs.com/package/publicodes-evenements). Le site est hébergé sur Netlify. Netlify est une entreprise américano-danoise. Son siège social se trouve à San Francisco, Californie. Le CDN européen de Netlify est situé à Francfort, en Allemagne.

## Vie privée

Nous ne collectons pas de données personnelles : toutes vos simulations sont stockées uniquement dans votre navigateur (si vous souhaitez sauvegarder vos simulations, vous pouvez les exporter en format JSON).

Nous suivons néanmoins quelques métriques telles que les pages consultées et le temps passé, dans un objectif d’amélioration de la plateforme. Nous utilisons [Simple Analytics](https://www.simpleanalytics.com/fr) pour gérer ce suivi. Vous pouvez consulter leur politique de confidentialité [ici](https://docs.simpleanalytics.com/what-we-collect). Les données collectées sont très réduites (pas de cookies, pas de collecte de l'adresse IP par exemple). Par ailleurs, notre page de statistiques est publique et accessible [ici](https://simpleanalytics.com/ekofest.fr).

## Contact et retours

La version actuelle d'ekofest est toujours en construction, que ce soit le site mais également le modèle de calcul.

Si vous avez une question, une suggestion ou un retour de bug vous pouvez nous écrire directement sur [Github](https://github.com/ekofest/ekofest/issues/new) ou bien nous contacter par mail aux adresses suivantes :

-   emile.rolley@tuta.io
-   clement.auger@beta.gouv.fr
