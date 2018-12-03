//: Playground - noun: a place where people can play

import Foundation

let optionalNum = ["1", "2", "Bob"]

let numbersArr = optionalNum.flatMap { Int($0) }


let arrOfArrs = [["1", "2", "Bob"], ["1", "2", "Bob"], ["1", "2", "Bob"]]

let arrOfArrs2 = arrOfArrs.flatMap { $0.flatMap { Int($0) } }

let arrOfArrs22 = arrOfArrs.map { $0.flatMap { Int($0) } }

print(arrOfArrs2)

print(arrOfArrs22)
