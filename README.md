# Level 10

![Level 10: Multiplayer iOS game built with
SwiftUI](https://repository-images.githubusercontent.com/492698930/25c2ecef-276d-4ba3-92f4-7c00871db4c8)

A multiplayer iOS game built with SwiftUI as a client for the [Level 10
server](https://github.com/dnsbty/level10). All communication with the server
happens over websockets and the UI is updated using the Coordinator pattern.

## Features

* Websocket communication with UI updating in real-time with other players'
  moves
* All interfaces built with SwiftUI
* Haptics and sound effects alert you when it's your turn
* Presence tracks and displays whether or not a user is currently connected to the game
* Push notifications are sent when the user isn't connected
* Modal is shown when the installed app version is no longer supported
* Requests a review when the game is over
* Universal links for inviting friends to play with you
* Custom modals and error banners using SwiftUI animation

## To Do

* Drag and drop cards in the game
* Multiple select cards with two-finger swipe
* Add a tutorial
* Add UI testing
* Allow players to change card sort order
* Add multiple app icons
* Various refactoring initiatives

## License

This project is under the MIT license. While it is not strictly forbidden by the
license, I would greatly appreciate it if you didn't redistribute this app
exactly the way it is in the App Store. There's nothing stopping you, but please
don't be a jerk.
