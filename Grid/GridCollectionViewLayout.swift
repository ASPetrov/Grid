//
//  GridCollectionViewLayout.swift
//  Grid
//
//  Created by Alexandar Petrov on 12/24/16.
//  Copyright © 2016 In-house Development. All rights reserved.
//

import UIKit

//MARK: - Layout

class GridViewLayout: UICollectionViewLayout {
    
    //MARK: - Setup
    
    private var isInitialized: Bool = false
    
    //MARK: - Attributes
    
    var attributesList: [[UICollectionViewLayoutAttributes]] = []
    
    //MARK: - Size
    
    private static let defaultGridViewItemHeight: CGFloat = 47
    private static let defaultGridViewItemWidth: CGFloat = 160
    
    static let defaultGridViewRowHeaderWidth: CGFloat = 200
    static let defaultGridViewColumnHeaderHeight: CGFloat = 80
    
    static let defaultGridViewItemSize: CGSize =
        CGSize(width: defaultGridViewItemWidth, height: defaultGridViewItemHeight)
    
    // This is regular cell size
    var itemSize: CGSize = defaultGridViewItemSize
    
    // Row Header Size
    var rowHeaderSize: CGSize =
        CGSize(width: defaultGridViewRowHeaderWidth, height: defaultGridViewItemHeight)
    
    // Column Header Size
    var columnHeaderSize: CGSize =
        CGSize(width: defaultGridViewItemWidth, height: defaultGridViewColumnHeaderHeight)
    
    var contentSize : CGSize!
    
    //MARK: - Layout
    
    private var columnsCount: Int = 0
    private var rowsCount: Int = 0
    
    private var includesRowHeader: Bool = false
    private var includesColumnHeader: Bool = false
    
    override func prepare() {
        super.prepare()
        
        rowsCount = collectionView!.numberOfSections
        if rowsCount == 0 { return }
        columnsCount = collectionView!.numberOfItems(inSection: 0)
        
        // make header row and header column sticky if needed
        if self.attributesList.count > 0 {
            for section in 0..<rowsCount {
                for index in 0..<columnsCount {
                    if section != 0 && index != 0 {
                        continue
                    }
                    
                    let attributes : UICollectionViewLayoutAttributes =
                        layoutAttributesForItem(at: IndexPath(forRow: section, inColumn: index))!
                    
                    if includesColumnHeader && section == 0 {
                        var frame = attributes.frame
                        frame.origin.y = collectionView!.contentOffset.y
                        attributes.frame = frame
                    }
                    
                    if includesRowHeader && index == 0 {
                        var frame = attributes.frame
                        frame.origin.x = collectionView!.contentOffset.x
                        attributes.frame = frame
                    }
                }
            }
            
            return // no need for futher calculations
        }

        // Read once from delegate
        if !isInitialized {
            if let delegate = collectionView!.delegate as? UICollectionViewDelegateGridLayout {
                
                // Calculate Item Sizes
                let indexPath = IndexPath(forRow: 0, inColumn: 0)
                let _itemSize = delegate.collectionView(collectionView!,
                                                        layout: self,
                                                        sizeForItemAt: indexPath)
                
                let width = delegate.rowHeaderWidth(in: collectionView!,
                                                    layout: self)
                let _rowHeaderSize = CGSize(width: width, height: _itemSize.height)
                
                let height = delegate.columnHeaderHeight(in: collectionView!,
                                                         layout: self)
                let _columnHeaderSize = CGSize(width: _itemSize.width, height: height)
                
                if !__CGSizeEqualToSize(_itemSize, itemSize) {
                    itemSize = _itemSize
                }
                
                if !__CGSizeEqualToSize(_rowHeaderSize, rowHeaderSize) {
                    rowHeaderSize = _rowHeaderSize
                }
                
                if !__CGSizeEqualToSize(_columnHeaderSize, columnHeaderSize) {
                    columnHeaderSize = _columnHeaderSize
                }
                
                // Should enable sticky row and column headers
                includesRowHeader = delegate.shouldIncludeHeaderRow(in: collectionView!)
                includesColumnHeader = delegate.shouldIncludeHeaderColumn(in: collectionView!)
            }
            
            isInitialized = true
        }
        
        var column = 0
        var xOffset : CGFloat = 0
        var yOffset : CGFloat = 0
        var contentWidth : CGFloat = 0
        var contentHeight : CGFloat = 0
        
        for section in 0..<rowsCount {
            var sectionAttributes: [UICollectionViewLayoutAttributes] = []
            for index in 0..<columnsCount {
                var _itemSize: CGSize = .zero
                
                switch (section, index) {
                case (0, 0):
                    switch (includesRowHeader, includesColumnHeader) {
                    case (true, true):
                        _itemSize = CGSize(width: rowHeaderSize.width, height: columnHeaderSize.height)
                    case (false, true): _itemSize = columnHeaderSize
                    case (true, false): _itemSize = rowHeaderSize
                    default: _itemSize = itemSize
                    }
                case (0, _):
                    if includesColumnHeader {
                        _itemSize = columnHeaderSize
                    } else {
                        _itemSize = itemSize
                    }
                    
                case (_, 0):
                    if includesRowHeader {
                        _itemSize = rowHeaderSize
                    } else {
                        _itemSize = itemSize
                    }
                default: _itemSize = itemSize
                }
                
                let indexPath = IndexPath(forRow: section, inColumn: index)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                
                attributes.frame = CGRect(x: xOffset,
                                          y: yOffset,
                                          width: _itemSize.width,
                                          height: _itemSize.height).integral
                
                // allow others cells to go under
                if section == 0 && index == 0 { // top-left cell
                    attributes.zIndex = 1024
                } else if section == 0 || index == 0 {
                    attributes.zIndex = 1023 // any ohter header cell
                }
                
                // sticky part - probably just in case here
                if includesColumnHeader && section == 0 {
                    var frame = attributes.frame
                    frame.origin.y = collectionView!.contentOffset.y
                    attributes.frame = frame
                }
                
                if includesRowHeader && index == 0 {
                    var frame = attributes.frame
                    frame.origin.x = collectionView!.contentOffset.x
                    attributes.frame = frame
                }
                
                sectionAttributes.append(attributes)
                
                xOffset += _itemSize.width
                column += 1
                
                if column == columnsCount {
                    if xOffset > contentWidth {
                        contentWidth = xOffset
                    }
                    
                    column = 0
                    xOffset = 0
                    yOffset += _itemSize.height
                }
            }
            
            attributesList.append(sectionAttributes)
        }
        
        let attributes = self.attributesList.last!.last!
        
        contentHeight = attributes.frame.origin.y + attributes.frame.size.height
        self.contentSize = CGSize(width: contentWidth,
                                  height: contentHeight)
        
    }
    
    override var collectionViewContentSize: CGSize {
        return self.contentSize
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        var curLayoutAttribute: UICollectionViewLayoutAttributes? = nil
        
        if indexPath.section < self.attributesList.count {
            let sectionAttributes = self.attributesList[indexPath.section]
            
            if indexPath.row < sectionAttributes.count {
                curLayoutAttribute = sectionAttributes[indexPath.row]
            }
        }
        
        return curLayoutAttribute
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []
        for section in self.attributesList {
            let filteredArray  =  section.filter({ (evaluatedObject) -> Bool in
                return rect.intersects(evaluatedObject.frame)
            })
            
            attributes.append(contentsOf: filteredArray)
        }
        
        return attributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    //MARK: - Moving
    
    override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath,
                                                             withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        guard let dest = super.layoutAttributesForItem(at: indexPath as IndexPath)?.copy() as? UICollectionViewLayoutAttributes else { return UICollectionViewLayoutAttributes() }
        
        dest.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        dest.alpha = 0.8
        dest.center = position

        return dest
    }
    
    override func invalidationContext(forInteractivelyMovingItems targetIndexPaths: [IndexPath],
                                      withTargetPosition targetPosition: CGPoint,
                                      previousIndexPaths: [IndexPath],
                                      previousPosition: CGPoint) -> UICollectionViewLayoutInvalidationContext {
        let context =  super.invalidationContext(forInteractivelyMovingItems: targetIndexPaths,
                                                 withTargetPosition: targetPosition,
                                                 previousIndexPaths: previousIndexPaths,
                                                 previousPosition: previousPosition)
        
        collectionView!.dataSource?.collectionView?(collectionView!,
                                                    moveItemAt: previousIndexPaths[0],
                                                    to: targetIndexPaths[0])
        
        return context
    }
    
}

//MARK: - Layout Delegate

protocol UICollectionViewDelegateGridLayout : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    func columnHeaderHeight(in collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout) -> CGFloat
    func rowHeaderWidth(in collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout) -> CGFloat
    
    func shouldIncludeHeaderRow(in collectionView: UICollectionView) -> Bool
    func shouldIncludeHeaderColumn(in collectionView: UICollectionView) -> Bool
    
}

//MARK: - Cells

class GridColumnHeaderCell: UICollectionViewCell { }

class GridRowHeaderCell: UICollectionViewCell { }

class GridItemCell: UICollectionViewCell { }

//MARK: - IndexPath

extension IndexPath {
    
    init(forRow row: Int, inColumn column: Int) {
        self.init(row: column, section: row)
    }
    
    var gridColumn: Int {
        return row
    }
    
    var gridRow: Int {
        return section 
    }
    
}

//MARK: - GridView Delegate

protocol GridViewDelegate: class {
    func gridView(_ gridView: GridView,
                  layout gridViewLayout: GridViewLayout,
                  sizeForItemAt indexPath: IndexPath) -> CGSize
    func columnHeaderHeight(in gridView: GridView,
                            layout gridViewLayout: GridViewLayout) -> CGFloat
    func rowHeaderWidth(in gridView: GridView,
                        layout gridViewLayout: GridViewLayout) -> CGFloat
}

//MARK: - GridView DataSource

protocol GridViewDataSource: class {
    
    func shouldIncludeHeaderRow(in gridView: GridView) -> Bool
    func shouldIncludeHeaderColumn(in gridView: GridView) -> Bool
    
    func numberOfRows(in gridView: GridView) -> Int
    func numberOfColumns(in gridView: GridView) -> Int
    
    func gridView(_ gridView: GridView, cellForRowHeaderAt index: Int) -> GridRowHeaderCell
    func gridView(_ gridView: GridView, cellForColumnHeaderAt index: Int) -> GridColumnHeaderCell
    func gridView(_ gridView: GridView,
                  cellForItemAt indexPath: IndexPath) -> GridItemCell
    
    func gridView(_ gridView: GridView,
                  moveItemAt sourceColumnHeaderIndex: Int,
                  to destinationColumnHeaderIndex: Int)
    
}

//MARK: - GridView

class GridView: UIView {
    
    fileprivate var collectionView: SwappingCollectionView!
    
    //MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        collectionView.removeGestureRecognizer(longPressGesture)
    }
    
    //MARK: - Setup
    
    weak var delegate: GridViewDelegate?
    weak var dataSource: GridViewDataSource?
    
    private func setup() {
        setupCollectionView()
        setupGesture()
    }
    
    // collection view
    
    private func setupCollectionView() {
        let layout = GridViewLayout()
        
        let _frame = CGRect(origin: .zero, size: frame.size)
        collectionView = SwappingCollectionView(frame: _frame, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.isDirectionalLockEnabled = true
        collectionView.bounces = false

        self.addSubview(collectionView)
        
        registerTopLeftHeaderCell(UICollectionViewCell.self)
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    // gesture
    
    private var longPressGesture: UILongPressGestureRecognizer!
    
    private func setupGesture() {
        let action = #selector(GridView.handleLongPress(longPress:))
        let longPress = UILongPressGestureRecognizer.init(target: self, action: action)
        longPress.minimumPressDuration = 0.3
        
        self.collectionView.addGestureRecognizer(longPress)
    }
    
    //MARK: - Move Header
    
    fileprivate var pannedIndexPath: NSIndexPath?
    fileprivate var pannedView: UIImageView?
    fileprivate var processingGestureRecogznierId: Int?
    
    //MARK: - Reusable Cells
    
    // register
    
    private func registerTopLeftHeaderCell(_ cellClass: Swift.AnyClass?) {
        collectionView.register(cellClass,
                                forCellWithReuseIdentifier: .gridTopLeftHeaderCellReuseIdentifier)
    }
    
    func registerColumnHeaderCell(_ cellClass: Swift.AnyClass?) {
        collectionView.register(cellClass,
                                forCellWithReuseIdentifier: .gridColumnHeaderCellReuseIdentifier)
    }
    
    func registerRowHeaderCell(_ cellClass: Swift.AnyClass?) {
        collectionView.register(cellClass,
                                forCellWithReuseIdentifier: .gridRowHeaderCellReuseIdentifier)
    }
    
    func registerItemCell(_ cellClass: Swift.AnyClass?) {
        collectionView.register(cellClass,
                                forCellWithReuseIdentifier: .gridItemCellReuseIdentifier)
    }
    
    private func registerTopLeftHeaderNib(_ nib: UINib?) {
        collectionView.register(nib,
                                forCellWithReuseIdentifier: .gridTopLeftHeaderCellReuseIdentifier)
    }
    
    func registerColumnHeaderNibl(_ nib: UINib?) {
        collectionView.register(nib,
                                forCellWithReuseIdentifier: .gridColumnHeaderCellReuseIdentifier)
    }
    
    func registerRowHeaderNib(_ nib: UINib?) {
        collectionView.register(nib,
                                forCellWithReuseIdentifier: .gridRowHeaderCellReuseIdentifier)
    }
    
    func registerItemNib(_ nib: UINib?) {
        collectionView.register(nib,
                                forCellWithReuseIdentifier: .gridItemCellReuseIdentifier)
    }
    
    // dequeue
    
    fileprivate func dequeueTopLeftHeaderCell() -> UICollectionViewCell {
        let indexPath = IndexPath(forRow: 0, inColumn: 0)
        return collectionView.dequeueReusableCell(withReuseIdentifier: .gridTopLeftHeaderCellReuseIdentifier,
                                                  for: indexPath)
    }
    
    func dequeueColumnHeaderCell(for index: Int) -> GridColumnHeaderCell {
        let indexPath = IndexPath(forRow: 0, inColumn: index)
        return collectionView.dequeueReusableCell(withReuseIdentifier: .gridColumnHeaderCellReuseIdentifier,
                                                  for: indexPath) as! GridColumnHeaderCell
    }
    
    func dequeueRowHeaderCell(for index: Int) -> GridRowHeaderCell {
        let indexPath = IndexPath(forRow: index, inColumn: 0)
        return collectionView.dequeueReusableCell(withReuseIdentifier: .gridRowHeaderCellReuseIdentifier,
                                                  for: indexPath) as! GridRowHeaderCell
    }
    
    func dequeueGridItemCell(for indexPath: IndexPath) -> GridItemCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: .gridItemCellReuseIdentifier,
                                                  for: indexPath) as! GridItemCell
    }
    
    //MARK: - Reload Data
    
    func reloadData() {
        self.collectionView.collectionViewLayout.prepare()
        self.collectionView.reloadData()
    }
    
}

extension GridView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let rows = dataSource?.numberOfRows(in: self) ?? 0
        let includesRowHeader =
            dataSource?.shouldIncludeHeaderRow(in: self) ?? false
        return rows + (includesRowHeader ? 1 : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let columns = dataSource?.numberOfColumns(in: self) ?? 0
        let includesColumnHeader =
            dataSource?.shouldIncludeHeaderColumn(in: self) ?? false
        return columns + (includesColumnHeader ? 1 : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let includesRowHeader =
            dataSource?.shouldIncludeHeaderRow(in: self) ?? false
        let includesColumnHeader =
            dataSource?.shouldIncludeHeaderColumn(in: self) ?? false

        if includesRowHeader && includesColumnHeader && indexPath.gridRow == 0 && indexPath.gridColumn == 0 {
            // For now empty top left cell
            let emptyCell = dequeueTopLeftHeaderCell()
            emptyCell.backgroundColor = .lightGray
            return emptyCell
        }
        
        if includesRowHeader && indexPath.gridColumn == 0 {
            let rowIndex = indexPath.gridRow - (includesColumnHeader ? 1 : 0)
            return dataSource?.gridView(self, cellForRowHeaderAt: rowIndex) ?? GridRowHeaderCell()
        }
        
        if includesColumnHeader && indexPath.gridRow == 0 {
            let columnIndex = indexPath.gridColumn - (includesRowHeader ? 1 : 0)
            return dataSource?.gridView(self, cellForColumnHeaderAt: columnIndex) ?? GridColumnHeaderCell()
        }
        
        let rowIndex = indexPath.gridRow - (includesColumnHeader ? 1 : 0)
        let columnIndex = indexPath.gridColumn - (includesRowHeader ? 1 : 0)
        let _indexPath = IndexPath(forRow: columnIndex, inColumn: rowIndex)
        return dataSource?.gridView(self, cellForItemAt: _indexPath) ?? GridItemCell()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath)
        return (cell is GridColumnHeaderCell) // ??? Check something else
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        let includesRowHeader = dataSource?.shouldIncludeHeaderRow(in: self) ?? false
        let sourceColumnIndex = sourceIndexPath.gridColumn - (includesRowHeader ? 1 : 0)
        let destinationColumnIndex = destinationIndexPath.gridColumn - (includesRowHeader ? 1 : 0)
        dataSource?.gridView(self,
                             moveItemAt: sourceColumnIndex,
                             to: destinationColumnIndex)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath,
                        toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        let includesRowHeader = dataSource?.shouldIncludeHeaderRow(in: self) ?? false
        if originalIndexPath.section == proposedIndexPath.section {
            if !includesRowHeader || proposedIndexPath.row > 0 {
                return proposedIndexPath
            }   
        }
        
        return originalIndexPath
    }
}

extension GridView: UICollectionViewDelegateGridLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! GridViewLayout
        return delegate?.gridView(self, layout: layout, sizeForItemAt: indexPath) ?? GridViewLayout.defaultGridViewItemSize
    }
    
    func columnHeaderHeight(in collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
        let layout = collectionViewLayout as! GridViewLayout
        return delegate?.columnHeaderHeight(in: self, layout: layout) ?? GridViewLayout.defaultGridViewColumnHeaderHeight
    }
    
    func rowHeaderWidth(in collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout) -> CGFloat {
        let layout = collectionViewLayout as! GridViewLayout
        return delegate?.rowHeaderWidth(in: self, layout: layout) ?? GridViewLayout.defaultGridViewRowHeaderWidth
    }
    
    func shouldIncludeHeaderRow(in collectionView: UICollectionView) -> Bool {
        return dataSource?.shouldIncludeHeaderRow(in: self) ?? false
    }
    
    func shouldIncludeHeaderColumn(in collectionView: UICollectionView) -> Bool {
        return dataSource?.shouldIncludeHeaderColumn(in: self) ?? false
    }
    
}

extension GridView {
    
    // MARK: - Handle Gesture
    
    func handleLongPress(longPress: UILongPressGestureRecognizer) {
        switch longPress.state {
        case .began:
            let location = longPress.location(in: collectionView)
            guard let selectedIndexPath = collectionView.indexPathForItem(at: location) else { return }
            _ = self.collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            let location = longPress.location(in: collectionView) // target
            guard let targetIndexPath = collectionView.indexPathForItem(at: location) else { return }
            collectionView.updateInteractiveMovementTargetPosition(location)
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
}

//MARK: - Cell Identifiers

extension String {
    static let gridTopLeftHeaderCellReuseIdentifier = "GridTopLeftHeaderCell"
    static let gridColumnHeaderCellReuseIdentifier = "GridColumnHeaderCell"
    static let gridRowHeaderCellReuseIdentifier = "GridRowHeaderCell"
    static let gridItemCellReuseIdentifier = "GridItemHeaderCell"
}

//MARK: - Snapshot

extension UIView {
    func snapshot() -> UIImage {
        UIGraphicsBeginImageContext(self.bounds.size)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

//MARK: - Point Distance Helper

extension CGPoint {
    func distanceToPoint(point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
    }
}

//MARK: - Swap Helper

struct SwapDescription : Hashable {
    var firstItem : Int
    var secondItem : Int
    
    var hashValue: Int {
        get {
            return (firstItem * 10) + secondItem
        }
    }
}

func ==(lhs: SwapDescription, rhs: SwapDescription) -> Bool {
    return lhs.firstItem == rhs.firstItem && lhs.secondItem == rhs.secondItem
}

//MARK: - Collection View

class SwappingCollectionView: UICollectionView {
    
    var interactiveIndexPath : IndexPath?
    var interactiveView : UIView?
    var interactiveCell : UICollectionViewCell?
    var swapSet : Set<SwapDescription> = Set()
    var previousPoint : CGPoint?
    
    static let distanceDelta:CGFloat = 2 // adjust as needed
    
    override func beginInteractiveMovementForItem(at indexPath: IndexPath) -> Bool {
        guard self.dataSource?.collectionView?(self, canMoveItemAt: indexPath) == true else { return false }
        
        self.interactiveIndexPath = indexPath
        
        self.interactiveCell = self.cellForItem(at: indexPath)
        
        self.interactiveView = UIImageView(image: self.interactiveCell?.snapshot())
        self.interactiveView?.frame = self.interactiveCell!.frame
        
        self.addSubview(self.interactiveView!)
        self.bringSubview(toFront: self.interactiveView!)
        
        self.interactiveCell?.isHidden = true
        
        return true
    }
    
    override func updateInteractiveMovementTargetPosition(_ targetPosition: CGPoint) {
        
        if (self.shouldSwap(newPoint: targetPosition)) {
            
            if let hoverIndexPath = self.indexPathForItem(at: targetPosition), let interactiveIndexPath = self.interactiveIndexPath {
                let destIndexPath = self.delegate?.collectionView?(self,
                                                                   targetIndexPathForMoveFromItemAt: interactiveIndexPath,
                                                                   toProposedIndexPath: hoverIndexPath) ?? hoverIndexPath
                print(hoverIndexPath, hoverIndexPath, destIndexPath)
                let swapDescription = SwapDescription(firstItem: interactiveIndexPath.item,
                                                      secondItem: destIndexPath.item)
                
                if (!self.swapSet.contains(swapDescription)) {
                    
                    self.swapSet.insert(swapDescription)
                    
                    self.performBatchUpdates({
                        self.moveItem(at: interactiveIndexPath, to: destIndexPath)
                        self.moveItem(at: destIndexPath, to: interactiveIndexPath)
                    }, completion: {(finished) in
                        self.swapSet.remove(swapDescription)
                        self.dataSource?.collectionView!(self,
                                                         moveItemAt: interactiveIndexPath,
                                                         to: destIndexPath)
                        self.interactiveIndexPath = destIndexPath
                        
                    })
                }
            }
        }
        
        self.interactiveView?.center = targetPosition
        self.previousPoint = targetPosition
    }
    
    override func endInteractiveMovement() {
        self.cleanup()
        self.reloadData()
    }
    
    override func cancelInteractiveMovement() {
        self.cleanup()
    }
    
    private func cleanup() {
        self.interactiveCell?.isHidden = false
        self.interactiveView?.removeFromSuperview()
        self.interactiveView = nil
        self.interactiveCell = nil
        self.interactiveIndexPath = nil
        self.previousPoint = nil
        self.swapSet.removeAll()
    }
    
    private func shouldSwap(newPoint: CGPoint) -> Bool {
        if let previousPoint = self.previousPoint {
            let distance = previousPoint.distanceToPoint(point: newPoint)
            return distance < SwappingCollectionView.distanceDelta
        }
        
        return false
    }
}
