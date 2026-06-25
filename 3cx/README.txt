DOSSIER À DÉPOSER DANS LE REPO  meyergold/site_srn  (à la racine, dossier "3cx")

Arborescence finale dans le repo :
  site_srn/
   └── 3cx/
        ├── index.html                     (la landing)
        ├── whitepaper_3cx_ulysse.html     (livre blanc web)
        ├── Livre_blanc_Sairen_x_3CX.pdf   (livre blanc PDF)
        ├── email_3cx_sairen.html          (à coller dans Monday, pas servi comme page)
        └── assets/
             ├── sairen_logo.png
             ├── tcx_logo.png
             └── av/  (sofia, clara, iris, lena .png  = agents IA du défilé)

URLS PUBLIQUES UNE FOIS POUSSÉ (après mise à jour GitHub Pages, ~1 min) :
  Landing      : https://meyergold.github.io/site_srn/3cx/
  Livre blanc  : https://meyergold.github.io/site_srn/3cx/whitepaper_3cx_ulysse.html
  PDF          : https://meyergold.github.io/site_srn/3cx/Livre_blanc_Sairen_x_3CX.pdf
  Logo Sairen  : https://meyergold.github.io/site_srn/3cx/assets/sairen_logo.png
  Logo 3CX     : https://meyergold.github.io/site_srn/3cx/assets/tcx_logo.png

L'email pointe déjà vers ces URLs (images + bouton "Recevoir le livre blanc").
Le bouton "Parler au service commercial" pointe vers le lien cal.com.

DEUX FAÇONS DE DÉPOSER :
1) Web GitHub : repo site_srn > Add file > Upload files > glisse le contenu,
   et dans le champ du chemin tape  3cx/  pour créer le dossier. Commit.
2) Git en local :
     git clone https://github.com/meyergold/site_srn.git
     # copie le dossier 3cx/ dedans
     git add 3cx && git commit -m "Campagne 3CX" && git push

VÉRIF : ouvre https://meyergold.github.io/site_srn/3cx/assets/sairen_logo.png
        -> si le logo s'affiche, l'email affichera les images.
