#  Abstract Factory design pattern in Swift

Design pattern belongs to Creational group of design patterns. This design pattern used to abstract the  creation of family objects. Objects created from one factory can interact with objects from the same factory, but must not interact with another factory.

Also all objects in this design pattern are abstracted with interfaces (protocols) and client of the factory doesn't know how objects are created, what types these objects are.

Let's create an example to see how it works.

Assume we have a Coffee Shop, where we can order some drinks like coffee, tea and water. Describe API of this shop via protocol:

```swift
protocol CoffeeShopFactory {
    func makeCoffee(_ sugar: Sugar) -> Coffee
    func makeTea(_ sugar: Sugar) -> Tea
    func makeWater() -> Water
    func makeSugar(spoons: Int) -> Sugar
}
```

Describe shop's products also with protocols:
 
 ```swift
protocol Drinkable { }
protocol Coffee: Drinkable { }
protocol Tea: Drinkable { }
protocol Water: Drinkable { }
protocol Sugar { }
```

Let's assume our app was released to App Store in Europe, where they (europeans) has its own set of preferred drinks in coffee shops.

```swift
final class EuropeanCoffeeShopFactory: CoffeeShopFactory {
    struct WhiteSugar: Sugar { let spoons: Int } // Assume europeans love white sugar
    func makeCoffee(_ sugar: Sugar) -> Coffee {
        // An assert just to show that `sugar` must be create the same factory.
        assert(type(of: sugar) == WhiteSugar.self)
        struct Latte: Coffee { let sugar: Sugar }
        return Latte(sugar: sugar)
    }
    func makeTea(_ sugar: Sugar) -> Tea {
        // An assert just to show that `sugar` must be create the same factory.
        assert(type(of: sugar) == WhiteSugar.self)
        struct GreenTea: Tea { let sugar: Sugar }
        return GreenTea(sugar: sugar)
    }
    func makeWater() -> Water {
        struct ArcticWater: Water { }
        return ArcticWater()
    }
    func makeSugar(spoons: Int) -> Sugar {
        return WhiteSugar(spoons: spoons)
    }
}
```

A bit later our app was released in US also, but americans prefer another set of drinks and another kind of sugar (not white, but gray).

```swift
final class USACoffeeShopFactory: CoffeeShopFactory {
    struct GraySugar: Sugar { let spoons: Int }
    func makeCoffee(_ sugar: Sugar) -> Coffee {
        // An assert just to show that `sugar` must be create the same factory.
        assert(type(of: sugar) == GraySugar.self)
        struct Espresso: Coffee { let sugar: Sugar }
        return Espresso(sugar: sugar)
    }
    func makeTea(_ sugar: Sugar) -> Tea {
        // An assert just to show that `sugar` must be create the same factory.
        assert(type(of: sugar) == GraySugar.self)
        struct BlackTea: Tea { let sugar: Sugar }
        return BlackTea(sugar: sugar)
    }
    func makeWater() -> Water {
        struct FilteredWater: Water { }
        return FilteredWater()
    }
    func makeSugar(spoons: Int) -> Sugar {
        return GraySugar(spoons: spoons)
    }
}
```

Now we are ready to create drinks in different locations (US vs EU).

```swift
struct Order { let drinks: [Drinkable] }
```

US Coffee shop:

```swift
let usShop: CoffeeShopFactory = CoffeeShopFactoryProvider.makeFactory()

// It is important that `sugar` must be created from the same
// factory as drinks.
let order = Order(drinks: [
    usShop.makeCoffee(usShop.makeSugar(spoons: 1)),
    usShop.makeCoffee(usShop.makeSugar(spoons: 2)),
    usShop.makeTea(usShop.makeSugar(spoons: 0)),
    usShop.makeWater()
])
```

EU Coffee shop:

```swift
let euShop: CoffeeShopFactory = CoffeeShopFactoryProvider.makeFactory()

let order = Order(drinks: [
    euShop.makeCoffee(euShop.makeSugar(spoons: 1)),
    euShop.makeCoffee(euShop.makeSugar(spoons: 2)),
    euShop.makeTea(euShop.makeSugar(spoons: 0)),
    euShop.makeWater()
])
```

But we must not be allowed to mix different shops as there are different families of objects. 

```swift
let coffee = euShop.makeCoffee(usShop.makeSugar(spoons: 1))
```

Look closer, we passed to EU coffee shop the sugar from US coffee shop that is violation of design pattern principle.

Also in Factory protocol we can go deeper in abstraction and replace `Coffee`, `Tea` and `Water` with `Drinkable` protocol.   
