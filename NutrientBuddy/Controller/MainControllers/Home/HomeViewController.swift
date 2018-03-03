//
//  ViewController.swift
//  DemoSearch
//
//  Created by Gemma Jing on 05/11/2017.
//  Copyright © 2017 Gemma Jing. All rights reserved.
//

import UIKit

func delay(_ delay: Double, closure: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: IBoutlet with the view
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var groupContainerView: UIView!
    @IBOutlet weak var progressGroup: MKRingProgressGroupView!
    @IBOutlet weak var waterBar: HomeWaterBarView!
    @IBOutlet weak var navigationBar: UINavigationItem!
    //ring graph button
    var buttons: [MKRingProgressGroupButton] = []
    var selectedIndex = 0
    
    //MARK: global variables
    var nutrientToView = NutrientTypeCoreDataHandler.fetchObject()!
    var display_nutrient: [foodInformation] = []
    let date = NutrientDiary().getDate()
    var personalGoals = PersonalSettingCoreDataHandler.fetchObject()!
    
    var energyGoal = 8700.0 // function to set
    var waterGoal = 1200.0 // function to set
    var percentages = percentageConsumed()
    
    override func viewDidAppear(_ animated: Bool) {
        //load personal goal
        if personalGoals.count == 0 {
            PersonalSettingCoreDataHandler.saveObject(carboGoal: 30, energyGoal: 8700, fatGoal: 20, proteinGoal: 50, waterGoal: 1200)
        }
        personalGoals = PersonalSettingCoreDataHandler.fetchObject()!
        if  debugPersonalSetting {
            print("GJ: there are \(personalGoals.count) elements in Goal core data")
        }
        let goal = personalGoals[0]
        
        //load summary
        let summaryAndPercentages = HomeViewFunctions().loadSummaryAndPercentages(waterGoal: goal.water_goal, energyGoal: goal.energy_goal, date: date, carboGoal: goal.carbo_goal, proteinGoal: goal.protein_goal, fatGoal: goal.fat_goal)
        let summary = summaryAndPercentages.summary
        percentages = summaryAndPercentages.percentages
        
        display_nutrient = HomeViewFunctions().loadFoodNutrition(nutrientToView: nutrientToView, summary: summary, date: date)
        
        //delete extra summaries
        HomeViewFunctions().deletePreviousNutrientSummaryIfExist(date: date)
        let newSummary = SummaryDiaryCoreDataHandler.fetchObject(date: date)
        if debugHomeView == true{
              print("GJ: there are \(newSummary.count) summaries in the core data now")
        }
        
        //ring graph
        randeringRingView()
        getSummaryPrecentageForRings()
        //water bar
        waterBar.drawProgressLayer(percentage: percentages.waterPercentage)
        //reload table
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if debugHomeView {
            print("GJ: today's date is \(date)")
        }
        //load personal goal
        if personalGoals.count == 0 {
            PersonalSettingCoreDataHandler.saveObject(carboGoal: 30, energyGoal: 8700, fatGoal: 20, proteinGoal: 50, waterGoal: 1200)
        }
        personalGoals = PersonalSettingCoreDataHandler.fetchObject()!
        if  debugPersonalSetting {
            print("GJ: there are \(personalGoals.count) elements in Goal core data")
        }
        let goal = personalGoals[0]
        
        //MARK: load the views
        //nutrient to view
        nutrientToView = HomeViewFunctions().getNutrientToView(nutrientToView: nutrientToView)
        
        //load summary
        let summaryAndPercentages = HomeViewFunctions().loadSummaryAndPercentages(waterGoal: goal.water_goal, energyGoal: goal.energy_goal, date: date, carboGoal: goal.carbo_goal, proteinGoal: goal.protein_goal, fatGoal: goal.fat_goal)
        let summary = summaryAndPercentages.summary
        percentages = summaryAndPercentages.percentages
        
        display_nutrient = HomeViewFunctions().loadFoodNutrition(nutrientToView: nutrientToView, summary: summary, date: date)
        
        //delete extra summaries
        HomeViewFunctions().deletePreviousNutrientSummaryIfExist(date: date)
        let newSummary = SummaryDiaryCoreDataHandler.fetchObject(date: date)
        if debugHomeView {
             print("GJ: there are \(newSummary.count) summaries in the core data now")
        }
        
        //ring graph
        randeringRingView()
        getSummaryPrecentageForRings()
        //water bar
        waterBar.drawProgressLayer(percentage: percentages.waterPercentage)
        //reload table
        tableView.reloadData()
    }

    //MARK: ring graphs
    func randeringRingView() {
        let containerView = UIView(frame: navigationController!.navigationBar.bounds)
        navigationController!.navigationBar.addSubview(containerView)
        let w = (containerView.bounds.width - 16) / CGFloat(7)
        let h = containerView.bounds.height
        let button = MKRingProgressGroupButton(frame: CGRect(x: CGFloat(0) * w, y: 0, width: w, height: h))
        button.contentView.ringWidth = 4.5
        button.contentView.ringSpacing = 1
        button.contentView.ring1StartColor = progressGroup.ring1StartColor
        button.contentView.ring1EndColor = progressGroup.ring1EndColor
        button.contentView.ring2StartColor = progressGroup.ring2StartColor
        button.contentView.ring2EndColor = progressGroup.ring2EndColor
        button.contentView.ring3StartColor = progressGroup.ring3StartColor
        button.contentView.ring3EndColor = progressGroup.ring3EndColor
        button.contentView.ring4StartColor = progressGroup.ring4StartColor
        button.contentView.ring4EndColor = progressGroup.ring4EndColor
        containerView.addSubview(button)
        buttons.append(button)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        buttons[0].isSelected = true
        
        delay(0.5) {
            self.updateMainGroupProgress()
        }
    }
    @objc func buttonTapped(_ sender: MKRingProgressGroupButton) {
        let newIndex = buttons.index(of: sender) ?? 0
        let dx = (newIndex > selectedIndex) ? -self.view.frame.width : self.view.frame.width
        
        buttons[selectedIndex].isSelected = false
        sender.isSelected = true
        selectedIndex = newIndex
        
        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
            self.groupContainerView.transform = CGAffineTransform(translationX: dx, y: 0)
        }) { (_) -> Void in
            self.groupContainerView.transform = CGAffineTransform(translationX: -dx, y: 0)
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.0)
            self.progressGroup.ring1.progress = 0.0
            self.progressGroup.ring2.progress = 0.0
            self.progressGroup.ring3.progress = 0.0
            self.progressGroup.ring4.progress = 0.0
            CATransaction.commit()
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
                self.groupContainerView.transform = CGAffineTransform.identity
            }, completion: { (_) -> Void in
                self.updateMainGroupProgress()
            })
        }
    }
    
    private func updateMainGroupProgress() {
        let selectedGroup = buttons[selectedIndex]
        CATransaction.begin()
        CATransaction.setAnimationDuration(1.0)
        self.progressGroup.ring1.progress = selectedGroup.contentView.ring1.progress
        self.progressGroup.ring2.progress = selectedGroup.contentView.ring2.progress
        self.progressGroup.ring3.progress = selectedGroup.contentView.ring3.progress
        self.progressGroup.ring4.progress = selectedGroup.contentView.ring4.progress
        CATransaction.commit()
    }
    
    //get summart for protain, fat, carbohydrate and energy
    @IBAction func getSummaryPrecentageForRings(_ sender: AnyObject? = nil) {
        for button in buttons {
            button.contentView.ring1.progress = percentages.energyPercentage
            button.contentView.ring2.progress = percentages.fatPercentage
            button.contentView.ring3.progress = percentages.proteinPercentage
            button.contentView.ring4.progress = percentages.carboPercentage
        }
        updateMainGroupProgress()
    }
    
    //MARK: table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return display_nutrient.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nutrientsDiary", for: indexPath) as! HomeTableViewCell
        let nutrientToDisplay = display_nutrient[indexPath.row]
        cell.nutrientTypeLabel.text = nutrientToDisplay.nutrientType
        var amountString = String(format: "%.3f", nutrientToDisplay.amount)
        amountString.append(nutrientToDisplay.unit)
        cell.nutrientAmountLabel.text = amountString
        //cell.contentView.setNeedsLayout()
        return cell
    }
    
}

