# 🧟 Zombie Survival iOS - 100 Niveaux & Éditeur

Jeu de tir et survie zombie dynamique développé nativement en **Swift** et **SpriteKit** pour iOS, avec compilation et packaging automatique d'archive `.ipa` via **GitHub Actions**.

---

## 🎮 Fonctionnalités

- **Gameplay addictif & soigné** :
  - Déplacement fluide via joystick virtuel et bouton de tir automatique/semi-auto.
  - Système d'éclairage dynamique (effet de cône lampe torche en temps réel).
  - Particules de sang, étincelles au canon (muzzle flash) et explosions à chaque zombie abattu.
  - Multiples types de zombies :
    - 🟢 **Zombie Normal** : Équilibré.
    - 🟡 **Zombie Rapide** : Véloce et agressif.
    - 🔴 **Zombie Tank** : Résistant et massif.
- **100 Niveaux préconçus & progressifs** :
  - Génération procédurale de difficultés (points de vie accrus, vitesses et densité de hordes).
  - Variations de disposition des obstacles et murs tactiques.
- **🛠️ Éditeur de Niveaux Intégré** :
  - Posez vos propres murs, obstacles et spawners de zombies sur une grille tactile.
  - Testez immédiatement votre niveau personnalisé.
  - Sauvegarde locale sur l'appareil.

---

## 📦 Compilation automatique du fichier `.ipa` sur GitHub

Un workflow GitHub Actions automatisé est configuré dans `.github/workflows/build-ios.yml`.

1. Poussez ce dossier sur votre dépôt : `https://github.com/flobure2008-ui/zombie`
2. Rendez-vous dans l'onglet **Actions** sur votre GitHub.
3. Le workflow **Build iOS IPA** se déclenche à chaque push (ou manuellement via "Run workflow").
4. Une fois terminé (sur machine macOS runner de GitHub), téléchargez le fichier `ZombieSurvival.ipa` prêt à installer dans la section **Artifacts** ou **Releases**.
5. Vous pouvez l'installer directement sur votre iPhone ou iPad avec **TrollStore**, **AltStore** ou **Sideloadly**.
