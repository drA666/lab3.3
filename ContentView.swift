//
//  ContentView.swift
//  RTS-Lab-3-3
//
//  Created by Rasiuk Alyona on 06.06.2021.
//
import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    @State var showAlert = false
    @State var bestResult = 0
    @State var bestResultIterationsNumber = 0

    var body: some View {
        VStack {
            inputs
            Spacer()
            output
            Spacer()
            button
            additionalTaskButton
        }
        .alert(isPresented: $showAlert) {
            let message = "Best result was gained with mutation \(bestResult * 10)% with number of iterations: \(bestResultIterationsNumber)"
            return Alert(title: Text("Best result"), message: Text(message))
        }
        .padding()
    }
    
    var inputs: some View {
        VStack {
            input("x1", for: 0)
            input("x2", for: 1)
            input("x3", for: 2)
            input("x4", for: 3)

            input("y", for: 4)
        }
    }
    
    @ViewBuilder
    var output: some View {
        if let error = viewModel.error {
            Text(error)
        } else {
            Text(viewModel.result)
        }
    }
    
    var button: some View {
        Button {
            viewModel.begin()
        } label: {
            Text("Compute")
        }
    }
    
    var additionalTaskButton: some View {
        Button {
            let additionalTaskResult = viewModel.additionalTask()
            print(additionalTaskResult)
            bestResultIterationsNumber = additionalTaskResult.filter { $0 != 0 }.min() ?? 0
            bestResult = additionalTaskResult.firstIndex(of: bestResultIterationsNumber) ?? 0
            showAlert.toggle()
        } label: {
            Text("Additional Task")
        }
    }
    
    func input(_ title: String, for index: Int) -> some View {
        HStack {
            Text("\(title):")
                .foregroundColor(.secondary)
            TextField("", text: $viewModel.input[index])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue))
    }
    
}

class ViewModel: ObservableObject {

    typealias Population = [[Double]]
    typealias PopulationRow = [Double]
    
    @Published var input = Array(repeating: "", count: 5)
    @Published var result = ""
    @Published var error: String? = nil
    @Published var iterationNumber = 0

    private var convertedInput = [Double]()
    
    public func begin() {
        error = nil
        result = ""

        guard let result = compute() else {
            error = "Coult not compute result in reasonable time"
            return
        }
        
        let left = zip(result.map { Int($0) }, convertedInput[..<(convertedInput.count - 1)].map { Int($0) })
            .map {
                "\($0) × \($1)"
            }
            .joined(separator: " + ")
        
        let right = "\(Int(convertedInput.last ?? 0))"

        self.result = [left, right].joined(separator: " = ")
    }

}

private extension ViewModel {
    
    func additionalTask() -> [Int] {
        var iterations = [Int]()
        for i in stride(from: 10, to: 110, by: 10) {
            let _ = compute(withMutation: i)
            iterations.append(iterationNumber)
        }
        
        return iterations
    }
    
    func compute(withMutation mutation: Int? = nil) -> PopulationRow? {
        iterationNumber = 0
        convertedInput = input
            .compactMap { Double.init($0) }
        
        guard convertedInput.count == input.count else {
            return nil
        }

        for i in 0..<1000 {
            var population = createZeroPopulation()

            for j in 0..<100 {
                let fitness = findFitness(population: population)
                if let index = fitness.firstIndex(of: 0) {
                    iterationNumber = i * j + j
                    return population[index]
                }
                let selection = playRoulette(population: population, fitness: fitness)
                let childPopulation = cross(selection: selection, mutation: mutation)
                population = childPopulation
            }
        }
        return nil
    }
    
    func createZeroPopulation() -> Population {
        var population = Population()
        for i in 0..<4 {
            population.append([])
            for _ in 0..<4 {
                let middle = Int(ceil((convertedInput.last ?? 0) / 2))
                population[i].append(Double(Int.random(in: 0...middle)))
            }
        }
        
        return population
    }
    
    func findFitness(population: Population) -> [Double] {
        population
            .map {
                let coefs = convertedInput[..<(convertedInput.count - 1)].map{ Double($0) }
                let y = convertedInput.last ?? 0
                return (y - zip($0, coefs).reduce(0, { $0 + $1.0 * $1.1 })).magnitude
            }
    }
    
    func playRoulette(population: Population, fitness: [Double]) -> Population {
        let rouletteValue = fitness.reduce(0, { $0 + (1 / $1) })
        let percentRoulette: [Double] = fitness.map { 1 / ($0 * rouletteValue) }
        var rouletteCircle = [Double]()
        for i in percentRoulette.indices {
            rouletteCircle.append(percentRoulette[i] + (i == 0 ? 0 : rouletteCircle[i - 1]))
        }
        
        var selection = Population()

        for _ in population.indices {
            let shot = Double.random(in: 0..<1)
            let index = rouletteCircle.lastIndex { shot >= $0 } ?? 0
            selection.append(population[index])
        }

        return selection
    }
    
    func cross(selection: Population, mutation: Int? = nil) -> Population {
        var childPopulation = Population()
        
        for i in selection.indices {
            var cross = [Double]()
            
            for j in selection.indices {
                if i % 2 == 0 {
                    cross.append(selection[j < 2 ? i : i + 1][j])
                } else {
                    cross.append(selection[j < 2 ? i : i - 1 ][j])
                }
            }

            childPopulation.append(cross)
        }
        
        if let mutation = mutation {
            let mutatedChildPopulation: Population = childPopulation.map { population in
                population.map {
                    let bound = $0 * Double(mutation / 100)
                    return $0 + ceil(Double.random(in: -bound...bound))
                }
            }
            return mutatedChildPopulation
        } else {
            return childPopulation
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
    }

}
