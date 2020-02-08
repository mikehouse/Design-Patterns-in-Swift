//
//  AbstractFactory.swift
//  Design Patterns in Swift
//
//  Created by Mikhail Demidov on 01.02.2020.
//  Copyright © 2020 Mikhail Demidov. All rights reserved.
//

import Foundation

/// Objects for client to use.

private protocol Drinkable { }
private protocol Coffee: Drinkable { }
private protocol Tea: Drinkable { }
private protocol Water: Drinkable { }

/// Internal ingredients shared between shop's products.
/// This is important that each factory has its own set of ingredients.
/// These unique ingredients separate one factory from another.

private protocol Sugar { }

private protocol CoffeeShopFactory {
    func makeCoffee(_ sugar: Sugar) -> Coffee
    func makeTea(_ sugar: Sugar) -> Tea
    func makeWater() -> Water
    func makeSugar(spoons: Int) -> Sugar
}

private final class EuropeanCoffeeShopFactory: CoffeeShopFactory {
    private struct WhiteSugar: Sugar { let spoons: Int }
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

private final class USACoffeeShopFactory: CoffeeShopFactory {
    private struct GraySugar: Sugar { let spoons: Int }
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

private final class CoffeeShopFactoryProvider {
    private enum Locale: CaseIterable {
        case eu // App released in EU market.
        case us // App released in US marker.
    }
    static func makeFactory() -> CoffeeShopFactory {
        switch Locale.allCases.shuffled()[0] {
        case .eu:
            return EuropeanCoffeeShopFactory()
        case .us:
            return USACoffeeShopFactory()
        }
    }
}

private struct Order { let drinks: [Drinkable] }

private let factory: CoffeeShopFactory = CoffeeShopFactoryProvider.makeFactory()

// It is important that `sugar` must be created from the same
// factory as drinks.
private let order = Order(drinks: [
    factory.makeCoffee(factory.makeSugar(spoons: 1)),
    factory.makeCoffee(factory.makeSugar(spoons: 2)),
    factory.makeTea(factory.makeSugar(spoons: 0)),
    factory.makeWater()
])
