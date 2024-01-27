# Description
Peach is a realtime chatting app focused on fast data transmission and updates.  
Pushing my limits to create a unique user interface while also maintaining high functionality and performance for better user experience.  
Open-sourcing my experimentation with Flutter in chat applications.

# Features
1. Send and recieve messages in real-time. Notifying users when you message them and they're not online.
2. Realtime online, typing and message read signals.
3. Fast and easy way to add contacts. Just scan QR code from your camera or gallery.
4. Create a profile with customizable settings like: active status, read recepients and recieving notifications allowence.
5. Send Multimedia (Image or audio), or instantly record voice messages.
6. Recting to messages with heart.
7. Delete your messages with no sign of existence.

# What did I create new in this app?

## Delayed Animation Builder
I was trying to find a way to fire multiple sequneced animation that can be repeated or reversed with specific amount of delay.
Firing `AnimationController` with `Future.delayed()` method would still occur much more delay than it should and would ruin the animation as whole.
So I tried to go to basics and understand how animations work in Flutter, and I learned about `Ticker` and how to use them.
### How does is work?
I built a widget that takes the number of animations you want to fire, the delay between, the controller you will use to forward and reverse the animation, and a builder where the values will be gives as double list.
It basically create a ticker that run over infinite amount of time, and based on the value of that elapsed time it will return the correct value, with different timelines for other values, so basically if we have coordinate system where X is the time and Y is the value, it will return different Y Values based on different X values that are shifted accordingly.
Up untill the last value of animations reaches `1.0` then it cancels the `Ticker`.
This widget can reverse, repeat, or run only once then reverse whenever with the controller, it also has an endcallabk when the animation is done.

### Sub Widgets: UpwardCrossFade
It's a really small widget that animates the child widgets fading in and up to make it look like it's starting to appear.

### Further Adjusments
The widget need MUCH MUCH further improvements.
For example: 
The controller was created last second and it's so sketchy so I definetly want to enhance that.
The widget constructor takes too many arguments which makes the code looks huge.
And so much more
But it did the job for now and I was happy with the results so I will leave it at this for now.



## AnimatedValue
When it comes to animation, I love to animated pretty much every element on the screen, but that can be quite costing, both for work and excution. So I tried to make a simple widget that takes a `dynamic` value of whatever type, and when that value changes the widget will rebuild it's child with animated value between the old one and the new one, that way you can pretty easily animate any value you want with just this simple widget.
It also is inspired from the many official widgets available like `AnimatedPositioned`, `AnimatedScale` etc...
The only problem there was is that they didn't conclude all kinds, at some point I wanted something like color, or just a double but I don't want to go through all the trouble of creating `AnimationController` and `Animation<double>` if i want to make it curved and so on.
So this widget was definetly much help
### How does it work
Pretty simple really all it does that every `build()` it checks if the value of the parent changed and if so it creates an animation between the old value and the new one and rebuild the child widget with the animated value.
### Further Improvements
[1] Create reverse curve.  
[2] Make it more user friendly.  

## CrossFadeSwitcher
I loved the `AnimatedSwitcher` package, the only problem was that it was the animating the two widgets with the same animation but with different values.
For example: if I want the animation to be fade transform animation, the two widgets would come from the same direction, and that just didn't do it for me.
I wanted more like pushing away animation in most of my cases so I created a similar widget that fades in and pushes away the old widget while it fades out.
Pretty simple yet neat.


## IconSwitcher
Pretty simple animation widgets that animates between two `Icons` (or really any type of widgets but I just used it for `Icons`)


## Switcher
A simple switcher with a callback for what value is selected and what actions to take, I'm not sure if there was already official switchers in flutter but I wanted to creat mine with a simple animation so here we are.
### Further Improvements
Definetly add more style to it, make it more customizable both in design and animation, right now it looks so plain, but then again it does the job so I'll leave it for now.


## AnimatedList
There is two version of animated lists I create, because the official `AnimatedList` has a lot of flaws and it's really hard to go very advanced with it especially that there is no swapping animations or such.
I wanted to create my own animated list, one for chat rooms from outside, and one for chat messages inside the chat rooms.
### How do they work
They basically create a cache list of previous children, and whenever you pass to the constructer different children they check for changes, whether you added new childre, removed some or swapped some. And then they apply animation to a list that contains both old and new children accordingly, and lastly they remove old children.
In addition, the chat rooms list creates initial animation for the first few widgets that appear on the screen as a starter animations.
### Further Improvements
1. Make the animations customizable
2. Expand it into `GridView` rather than just `ListView`
3. Handle children in more cleaner way

## TypingWidget
There are two typing widgets. one is the small three little dots that appear outside the chat room, and one inside the chat room.
The small little dots are pretty simple, they use the same concept as `DelayedAniamtionBuilder` only I had to create them before I created this widget so they don't directly use `DelayedAnimationBuilder`.
The chat room typing widget basically generates a text and then animate value from 0 to 1 to see how much of the text will it select to show, the text is randomly generated and hidden by a small container over it, and at the end of the animation it selects a random emoji to add to the message as well.

## LoadingWidget
It's really what inspired the `DelayedAnimationBuilder` whole code. I wanted to create that animation so bad and I had no idea how so I kept on crafting ways to do it untill I achieved that animation then I created `DelayedAnimationBuilder` to make every other alike animation easier with the same concept.

## Waveforms
For audio (recording and playing), I used [audio_waveforms packange]([https://pages.github.com/](https://pub.dev/packages/audio_waveforms)https://pub.dev/packages/audio_waveforms). Which to be honest wasn't really great, I wasn't able to customize most of things in the widgets, and the playing methods had many problems, so I only used the package to extract the waveforms from the audios and from the recording process and I used custom widgets to represent those waveforms data. And I used [audioplayers package](https://pub.dev/packages/audioplayers) to play the audio medias.
### How it works?
It takes the `List<double>` that represents audio waveforms values and then creates list of `Container`s and animates them gradually to appear or to resize.

# What did I experience new in this app?

## Firebase
Although I have created and used Firebase many times in my previous apps, It was in android native (Java) and also It was some time ago so there definetly a lot of changes with the `Firebase CLI` and everything, that made it feel a bit of new experience.
In this app I'm using 
```
Firebase Realtime Database
Firebase Storage
Firebase Authentication
Firebase Messagging
```
I'm also using a crappy handwritten `Node JS` app server that is currently uploaded on free host on [Render](https://www.render.com/) to access the Firebase admin panel and send notification messages from one user to another.

## QR Code
In this app I'm making the whole adding and connecting with people process through QR Codes. Altough it may not seem practical in the real world or atleast It would be nicer if there's a different method, I was always facsinated by the idea of just picking up your phone, scanning a code and that's it. It was always mindblowing for me and I wanted to apply it atleast in this application, but if there are more users on this app I'll probably consider adding a different methods to add contacts.
I used [qr_flutter Package](https://pub.dev/packages/qr_flutter) to generate the QR code that represents the user id. And I used [google_mlkit_barcode_scanning Packge](https://pub.dev/packages/google_mlkit_barcode_scanning), [camera Packge](https://pub.dev/packages/camera) and [image_picker Package](https://pub.dev/packages/google_mlkit_barcode_scanning) to scan QR codes from camera and gallery.


## Notifications
I have not dealt with notifications in Flutter before, so it definetly new for me to how handle notifications. In bigger projects I would've tried to implement notifications for every platform with my own platform-specific purposes, but because I didn't want to make it bigger than it should I used the [flutter_local_notifications Packge](https://pub.dev/packages/flutter_local_notifications) to send notifications and recieve responses from them.

## Cache
For my whole experience in coding, I have never cared about caching or data storage. So I definetly wanted to have more experience in that field.  
I have used [cahced_network_image Packge](https://pub.dev/packages/cached_network_image) for users' profile pictures, but as for the in-chat media (images and audios). I used [flutter_cache_manager Package](https://pub.dev/packages/flutter_cache_manager) to create my own cache manager and store media in them and restore them later on.  
Understanding cache and how it works definetly was challengin but also was to fun and practical to play with.



## What's next?
There's definetly a lot more to work on this app. For example:  
1. Making the code more readible and less messier, and probably trying to use clean code archticture.
2. Adding more conversation functionallities like voice and video call.  
3. Adding group chat functionality.
4. Adding AI bot to chat with.
5. Adding more media options like video and location option.  
6. Adding more settings to the user, like chat backup and privacy options.
7. Publish to different platforms: Although I have adjusted most packages to meet the requirements for different platforms, I have only been able to test it on the android. Therefore, it's currently the only platform the application is available on.
And lots more.
Right now I don't know where things will take me or will this be the last update for this application, but as for currently I would love to take a break from this one, work on something different and hopefully get back to it later on.

## Say Hello!
It would absloutely mean a lot to me to know that someone found this page and downloaded my application, so I added method to instantly add my account on the application. If you would like you can send me a message and I'll respond as soon as I can.






