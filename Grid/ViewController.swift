//
//  ViewController.swift
//  Grid
//
//  Created by Alexandar Petrov on 12/24/16.
//  Copyright © 2016 In-house Development. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var gridView: GridView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dummyProducts = [
            1, 2, 3, 4, 5, 6, 7, 8
        ]

        dummyProductsItems = [
            [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150],
            [11, 21, 31, 41, 51, 61, 71, 81, 91, 101, 111, 121, 131, 141, 151],
            [12, 22, 32, 42, 52, 62, 72, 82, 92, 102, 112, 122, 132, 142, 152],
            [13, 23, 33, 43, 53, 63, 73, 83, 93, 103, 113, 123, 133, 143, 153],
            [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150],
            [11, 21, 31, 41, 51, 61, 71, 81, 91, 101, 111, 121, 131, 141, 151],
            [12, 22, 32, 42, 52, 62, 72, 82, 92, 102, 112, 122, 132, 142, 152],
            [13, 23, 33, 43, 53, 63, 73, 83, 93, 103, 113, 123, 133, 143, 153],
        ]
        
        gridView.delegate = self
        gridView.dataSource = self
        
        let gridRowHeaderNib = UINib(nibName: "GridRowHeaderCell", bundle:nil)
        gridView.registerRowHeaderNib(gridRowHeaderNib)
        
        let gridColumnHeaderNib =
            UINib(nibName: "GridColumnHeaderCell", bundle:nil)
        gridView.registerColumnHeaderNibl(gridColumnHeaderNib)
        
        let gridItemNib = UINib(nibName: "GridItemCell", bundle:nil)
        gridView.registerItemNib(gridItemNib)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gridView.reloadData()
    }
    
    var dummyProducts: [Int] = []
    var dummyProductsItems: [[Int]] = []
}

extension ViewController: GridViewDelegate {
    func gridView(_ gridView: GridView,
                  layout gridViewLayout: GridViewLayout,
                  sizeForItemAt indexPath: IndexPath) -> CGSize {
        return GridViewLayout.defaultGridViewItemSize
    }
    
    func columnHeaderHeight(in gridView: GridView,
                            layout gridViewLayout: GridViewLayout) -> CGFloat {
        return GridViewLayout.defaultGridViewColumnHeaderHeight
    }
    
    func rowHeaderWidth(in gridView: GridView,
                        layout gridViewLayout: GridViewLayout) -> CGFloat {
        return GridViewLayout.defaultGridViewRowHeaderWidth
    }
}

extension ViewController: GridViewDataSource {
    func shouldIncludeHeaderRow(in gridView: GridView) -> Bool {
        return true
    }
    
    func shouldIncludeHeaderColumn(in gridView: GridView) -> Bool {
        return true
    }
    
    func numberOfRows(in gridView: GridView) -> Int {
        return dummyProductsItems[0].count
    }
    
    func numberOfColumns(in gridView: GridView) -> Int {
        return dummyProducts.count
    }
    
    func gridView(_ gridView: GridView,
                  cellForRowHeaderAt index: Int) -> GridRowHeaderCell {
        let cell = gridView.dequeueRowHeaderCell(for: index) as! TestGridRowHeaderCell
        // TODO: Actual Setup
        cell.titleLabel.text = "Row \(index+1)"
        return cell
    }
    
    func gridView(_ gridView: GridView,
                  cellForColumnHeaderAt index: Int) -> GridColumnHeaderCell {
        let cell = gridView.dequeueColumnHeaderCell(for: index) as! TestGridColumnHeaderCell
        // TODO: Actual Setup
        let item = dummyProducts[index]
        cell.titleLabel.text = "Column \(item)"
        return cell
    }
    
    func gridView(_ gridView: GridView,
                  cellForItemAt indexPath: IndexPath) -> GridItemCell {
        let cell = gridView.dequeueGridItemCell(for: indexPath) as! TestGridItemCell
        // TODO: Actual Setup
        let item = dummyProductsItems[indexPath.gridRow][indexPath.gridColumn]
        cell.titleLabel.text = "Cell \(item)"
        return cell
    }
    
    func gridView(_ gridView: GridView,
                  moveItemAt sourceColumnHeaderIndex: Int,
                  to destinationColumnHeaderIndex: Int) {
        let srcItems = self.dummyProductsItems[sourceColumnHeaderIndex]
        let destItems = self.dummyProductsItems[destinationColumnHeaderIndex]
        
        self.dummyProductsItems[destinationColumnHeaderIndex] = srcItems
        self.dummyProductsItems[sourceColumnHeaderIndex] = destItems
        
        let src = self.dummyProducts[sourceColumnHeaderIndex]
        let dest = self.dummyProducts[destinationColumnHeaderIndex]
        
        self.dummyProducts[destinationColumnHeaderIndex] = src
        self.dummyProducts[sourceColumnHeaderIndex] = dest
    }
    
}

final class TestGridColumnHeaderCell: GridColumnHeaderCell {
    @IBOutlet weak var titleLabel: UILabel!
}

final class TestGridRowHeaderCell: GridRowHeaderCell {
    @IBOutlet weak var titleLabel: UILabel!
}

final class TestGridItemCell: GridItemCell {
    @IBOutlet weak var titleLabel: UILabel!
}
