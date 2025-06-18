# Réservation parties communes résidence nemea
L'application Nemea est une solution mobile pour gérer la réservation des espaces communs dans les résidences étudiantes Nemea. Elle répond à un besoin réel : éviter les conflits et la désorganisation dans l'utilisation des espaces partagés (cuisine, salon, salle de sport, terrasse).

# Problématique
Les résidents utilisaient auparavant un groupe WhatsApp pour coordonner l'utilisation des espaces communs, ce qui entraînait :
* Des pertes d'information
* De la désorganisation
* Des frustrations dues aux conflits d'horaires

# Objectifs
- Centraliser la gestion des réservations dans une application dédiée
- Éviter les conflits en permettant de visualiser les créneaux occupés
- Simplifier le processus de réservation avec une interface intuitive
- Sécuriser l'accès aux seuls résidents authentifiés

# Architecture du projet 

lib/
├── main.dart                 # Point d'entrée de l'application
├── pages/                    # Interfaces utilisateur
│   ├── home.dart            # Navigation principale
│   ├── HomePage.dart        # Accueil avec dashboard
│   ├── LoginPage.dart       # Connexion
│   ├── RegisterPage.dart    # Inscription
│   ├── ProfilePage.dart     # Profil utilisateur
│   ├── AddBookingPage.dart  # Création de réservation
│   └── MyBookings.dart      # Liste des réservations
├── services/                 # Logique métier
│   ├── AuthService.dart     # Gestion de l'authentification
│   ├── AuthGate.dart        # Contrôle d'accès
│   ├── BookingService.dart  # Gestion des réservations
│   └── SpaceService.dart    # Gestion des espaces


## AuthService (Singleton)

- Gestion de l'authentification via Supabase Auth
- Création et gestion des profils utilisateurs
- Méthodes : signIn, signUp, signOut, getUserProfile

## BookingService (Singleton)

- CRUD des réservations
- Vérification des conflits horaires
- Suggestions de créneaux libres
- Gestion des erreurs avec messages utilisateur

## SpaceService

- Récupération des informations des espaces
- Interface avec la table Spaces de Supabase

# Base de Données
   Tables Supabase :

-Profiles : Informations utilisateurs (id, UUID, name, created_at)
-Spaces : Espaces disponibles (id, name, description)
-Bookings : Réservations (id, space_id, user_id, start_date, end_date)

# Fonctionnalités Implémentées
## Authentification

- Inscription avec email/mot de passe
- Connexion sécurisée
- Création automatique du profil utilisateur
- Déconnexion

## Gestion des Réservations

- Création de réservation avec processus guidé en 4 étapes :

1 Sélection de l'espace (Cuisine, Salon, Salle de sport, Terrasse)
2 Choix de la date via calendrier
3 Sélection des heures avec vérification des conflits
4 Confirmation de la réservation

-Visualisation des créneaux occupés en temps réel
-Suggestions de créneaux libres automatiques
-Prévention des conflits avec vérification avant validation

## Interface Utilisateur

Page d'accueil avec :

-Message de bienvenue personnalisé
-Prochaines réservations
-Espaces disponibles
-Activité récente


Mes Réservations avec :

- Filtres (Toutes, À venir, Passées)
- Annulation de réservation
- Détails complets (espace, date, durée)


Profil Utilisateur avec :

- Statistiques personnelles
- Modification du nom
- Déconnexion
