import Foundation

public enum LegendIcon {
    case square(Color)
    case shape(ScatterPlotSeriesOptions.ScatterPattern, Color)
}

public struct GraphLayout {
    // Inputs.
    var plotDimensions: PlotDimensions
    
    init(plotDimensions: PlotDimensions) {
        self.plotDimensions = plotDimensions
        self.plotDimensions.calculateGraphDimensions()
    }
    
    var plotTitle: PlotTitle? = nil
    var plotLabel: PlotLabel? = nil
    var plotLegend = PlotLegend()
    var plotBorder = PlotBorder()
    var grid = Grid()
    var legendLabels: [(String, LegendIcon)] = []
    
    var enablePrimaryAxisGrid = true
    var enableSecondaryAxisGrid = true
    var markerTextSize: Float = 12
    
    struct Results {
        var plotBorderRect: Rect?
        
        var xLabelLocation: Point?
        var yLabelLocation: Point?
        var titleLocation: Point?
        
        var plotMarkers = PlotMarkers()
        var xMarkersTextLocation = [Point]()
        var yMarkersTextLocation = [Point]()
        var y2MarkersTextLocation = [Point]()
        
        var legendRect: Rect?
    }
    
    // Layout.
        
    func layout(renderer: Renderer, calculateMarkers: (inout PlotMarkers)->Void) -> Results {
        var results = Results()
        calcBorderAndLegend(results: &results)
        calcLabelLocations(renderer: renderer, results: &results)
        calculateMarkers(&results.plotMarkers)
        calcMarkerTextLocations(renderer: renderer, results: &results)
        calcLegend(legendLabels, renderer: renderer, results: &results)
        return results
    }
    
    func calcBorderAndLegend(results: inout Results) {
        let borderRect = Rect(
            origin: Point(plotDimensions.subWidth * 0.1, plotDimensions.subHeight * 0.1),
            size: Size(width: plotDimensions.subWidth * 0.8,
                       height: plotDimensions.subHeight * 0.8)
        )
        results.plotBorderRect = borderRect
    }

    func calcLabelLocations(renderer: Renderer, results: inout Results) {
        if let plotLabel = plotLabel {
            let xWidth = renderer.getTextWidth(text: plotLabel.xLabel, textSize: plotLabel.size)
            let yWidth = renderer.getTextWidth(text: plotLabel.yLabel, textSize: plotLabel.size)
            results.xLabelLocation = Point(
                results.plotBorderRect!.midX - xWidth * 0.5,
                results.plotBorderRect!.minY - plotLabel.size - 0.05 * plotDimensions.graphHeight
            )
            results.yLabelLocation = Point(
                results.plotBorderRect!.origin.x - plotLabel.size - 0.05 * plotDimensions.graphWidth,
                results.plotBorderRect!.midY - yWidth
            )
        }
        if let plotTitle = plotTitle {
          let titleWidth = renderer.getTextWidth(text: plotTitle.title, textSize: plotTitle.size)
          results.titleLocation = Point(
            results.plotBorderRect!.midX - titleWidth * 0.5,
            results.plotBorderRect!.maxY + plotTitle.size * 0.5
          )
        }
    }
    
    func calcMarkerTextLocations(renderer: Renderer, results: inout Results) {
        
        for i in 0..<results.plotMarkers.xMarkers.count {
            let textWidth = renderer.getTextWidth(text: results.plotMarkers.xMarkersText[i], textSize: markerTextSize)
            let text_p = Point(
                results.plotMarkers.xMarkers[i] - (textWidth/2),
                -2.0 * markerTextSize
            )
            results.xMarkersTextLocation.append(text_p)
        }
        
        for i in 0..<results.plotMarkers.yMarkers.count {
            let text_p = Point(
                -(renderer.getTextWidth(text: results.plotMarkers.yMarkersText[i], textSize: markerTextSize)+8),
                results.plotMarkers.yMarkers[i] - 4
            )
            results.yMarkersTextLocation.append(text_p)
        }
        
        for i in 0..<results.plotMarkers.y2Markers.count {
            let text_p = Point(
                plotDimensions.graphWidth + 8,
                results.plotMarkers.y2Markers[i] - 4
            )
            results.y2MarkersTextLocation.append(text_p)
        }
    }
    
    func calcLegend(_ labels: [(String, LegendIcon)], renderer: Renderer, results: inout Results) {
        guard !labels.isEmpty else { return }
        let maxWidth = labels.lazy.map {
            renderer.getTextWidth(text: $0.0, textSize: self.plotLegend.textSize)
        }.max() ?? 0
        
        let legendWidth  = maxWidth + 3.5 * plotLegend.textSize
        let legendHeight = (Float(labels.count)*2.0 + 1.0) * plotLegend.textSize
        
        let legendTopLeft = Point(results.plotBorderRect!.minX + Float(20),
                                  results.plotBorderRect!.maxY - Float(20))
        results.legendRect = Rect(
            origin: legendTopLeft,
            size: Size(width: legendWidth, height: -legendHeight)
        ).normalized
    }
    
    // Drawing.
    
    func drawBackground(results: Results, renderer: Renderer) {
        drawGrid(results: results, renderer: renderer)
        drawBorder(results: results, renderer: renderer)
        drawMarkers(results: results, renderer: renderer)
    }
    
    func drawForeground(results: Results, renderer: Renderer) {
        drawTitle(results: results, renderer: renderer)
        drawLabels(results: results, renderer: renderer)
        drawLegend(legendLabels, results: results, renderer: renderer)
    }
    
    func drawTitle(results: Results, renderer: Renderer) {
        guard let plotTitle = self.plotTitle, let location = results.titleLocation else { return }
        renderer.drawText(text: plotTitle.title,
                          location: location,
                          textSize: plotTitle.size,
                          color: plotTitle.color,
                          strokeWidth: 1.2,
                          angle: 0,
                          isOriginShifted: false)
    }

    func drawLabels(results: Results, renderer: Renderer) {
        guard let plotLabel = self.plotLabel else { return }
        if let xLocation = results.xLabelLocation {
            renderer.drawText(text: plotLabel.xLabel,
                              location: xLocation,
                              textSize: plotLabel.size,
                              color: plotLabel.color,
                              strokeWidth: 1.2,
                              angle: 0,
                              isOriginShifted: false)
        }
        if let yLocation = results.yLabelLocation {
            renderer.drawText(text: plotLabel.yLabel,
                              location: yLocation,
                              textSize: plotLabel.size,
                              color: plotLabel.color,
                              strokeWidth: 1.2,
                              angle: 90,
                              isOriginShifted: false)
        }
    }
    
    func drawBorder(results: Results, renderer: Renderer) {
        guard let borderRect = results.plotBorderRect else { return }
        renderer.drawRect(borderRect,
                          strokeWidth: plotBorder.thickness,
                          strokeColor: plotBorder.color, isOriginShifted: false)
    }
    
    func drawGrid(results: Results, renderer: Renderer) {
        guard enablePrimaryAxisGrid || enablePrimaryAxisGrid else { return }
        for index in 0..<results.plotMarkers.xMarkers.count {
            let p1 = Point(results.plotMarkers.xMarkers[index], 0)
            let p2 = Point(results.plotMarkers.xMarkers[index], plotDimensions.graphHeight)
            renderer.drawLine(startPoint: p1,
                              endPoint: p2,
                              strokeWidth: grid.thickness,
                              strokeColor: grid.color,
                              isDashed: false,
                              isOriginShifted: true)
        }
    
        if (enablePrimaryAxisGrid) {
            for index in 0..<results.plotMarkers.yMarkers.count {
                let p1 = Point(0, results.plotMarkers.yMarkers[index])
                let p2 = Point(plotDimensions.graphWidth, results.plotMarkers.yMarkers[index])
                renderer.drawLine(startPoint: p1,
                                  endPoint: p2,
                                  strokeWidth: grid.thickness,
                                  strokeColor: grid.color,
                                  isDashed: false,
                                  isOriginShifted: true)
            }
        }
        if (enableSecondaryAxisGrid) {
            for index in 0..<results.plotMarkers.y2Markers.count {
                let p1 = Point(0, results.plotMarkers.y2Markers[index])
                let p2 = Point(plotDimensions.graphWidth, results.plotMarkers.y2Markers[index])
                renderer.drawLine(startPoint: p1,
                                  endPoint: p2,
                                  strokeWidth: grid.thickness,
                                  strokeColor: grid.color,
                                  isDashed: false,
                                  isOriginShifted: true)
            }
        }
    }

    func drawMarkers(results: Results, renderer: Renderer) {
        for index in 0..<results.plotMarkers.xMarkers.count {
            let p1 = Point(results.plotMarkers.xMarkers[index], -6)
            let p2 = Point(results.plotMarkers.xMarkers[index], 0)
            renderer.drawLine(startPoint: p1,
                              endPoint: p2,
                              strokeWidth: plotBorder.thickness,
                              strokeColor: plotBorder.color,
                              isDashed: false,
                              isOriginShifted: true)
            renderer.drawText(text: results.plotMarkers.xMarkersText[index],
                              location: results.xMarkersTextLocation[index],
                              textSize: markerTextSize,
                              color: plotBorder.color,
                              strokeWidth: 0.7,
                              angle: 0,
                              isOriginShifted: true)
        }

        for index in 0..<results.plotMarkers.yMarkers.count {
            let p1 = Point(-6, results.plotMarkers.yMarkers[index])
            let p2 = Point(0, results.plotMarkers.yMarkers[index])
            renderer.drawLine(startPoint: p1,
                              endPoint: p2,
                              strokeWidth: plotBorder.thickness,
                              strokeColor: plotBorder.color,
                              isDashed: false,
                              isOriginShifted: true)
            renderer.drawText(text: results.plotMarkers.yMarkersText[index],
                              location: results.yMarkersTextLocation[index],
                              textSize: markerTextSize,
                              color: plotBorder.color,
                              strokeWidth: 0.7,
                              angle: 0,
                              isOriginShifted: true)
        }
        
        if !results.plotMarkers.y2Markers.isEmpty {
            for index in 0..<results.plotMarkers.y2Markers.count {
                let p1 = Point(plotDimensions.graphWidth,
                               (results.plotMarkers.y2Markers[index]))
                let p2 = Point(plotDimensions.graphWidth + 6,
                               (results.plotMarkers.y2Markers[index]))
                renderer.drawLine(startPoint: p1,
                                  endPoint: p2,
                                  strokeWidth: plotBorder.thickness,
                                  strokeColor: plotBorder.color,
                                  isDashed: false,
                                  isOriginShifted: true)
                renderer.drawText(text: results.plotMarkers.y2MarkersText[index],
                                  location: results.y2MarkersTextLocation[index],
                                  textSize: markerTextSize,
                                  color: plotBorder.color,
                                  strokeWidth: 0.7,
                                  angle: 0,
                                  isOriginShifted: true)
            }
        }
    }
    
    func drawLegend(_ entries: [(String, LegendIcon)], results: Results, renderer: Renderer) {
        
        guard let legendRect = results.legendRect else { return }
        renderer.drawSolidRectWithBorder(legendRect,
                                         strokeWidth: plotLegend.borderThickness,
                                         fillColor: plotLegend.backgroundColor,
                                         borderColor: plotLegend.borderColor,
                                         isOriginShifted: false)
        
        for i in 0..<entries.count {
            let seriesIcon = Rect(
                origin: Point(legendRect.origin.x + plotLegend.textSize,
                              legendRect.maxY - (2.0*Float(i) + 1.0)*plotLegend.textSize),
                size: Size(width: plotLegend.textSize, height: -plotLegend.textSize)
            )
            switch entries[i].1 {
            case .square(let color):
                renderer.drawSolidRect(seriesIcon,
                                       fillColor: color,
                                       hatchPattern: .none,
                                       isOriginShifted: false)
            case .shape(let shape, let color):
                shape.draw(in: seriesIcon,
                           color: color,
                           renderer: renderer)
            }
            let p = Point(seriesIcon.maxX + plotLegend.textSize, seriesIcon.minY)
            renderer.drawText(text: entries[i].0,
                              location: p,
                              textSize: plotLegend.textSize,
                              color: plotLegend.textColor,
                              strokeWidth: 1.2,
                              angle: 0,
                              isOriginShifted: false)
        }
    }
}

public protocol HasGraphLayout: AnyObject {
    
    var layout: GraphLayout { get set }
    
    var legendLabels: [(String, LegendIcon)] { get }
    
    func calculateScaleAndMarkerLocations(markers: inout PlotMarkers, renderer: Renderer)
    
    func drawData(markers: PlotMarkers, renderer: Renderer)
}

extension HasGraphLayout {
    
    public var plotDimensions: PlotDimensions {
        get { layout.plotDimensions }
        set { layout.plotDimensions = newValue }
    }
    
    public var plotTitle: PlotTitle? {
        get { layout.plotTitle }
        set { layout.plotTitle = newValue }
    }
    public var plotLabel: PlotLabel? {
        get { layout.plotLabel }
        set { layout.plotLabel = newValue }
    }
    public var plotLegend: PlotLegend {
        get { layout.plotLegend }
        set { layout.plotLegend = newValue }
    }
    public var plotBorder: PlotBorder {
        get { layout.plotBorder }
        set { layout.plotBorder = newValue }
    }
    public var grid: Grid {
        get { layout.grid }
        set { layout.grid = newValue }
    }

    public var markerTextSize: Float {
        get { layout.markerTextSize }
        set { layout.markerTextSize = newValue }
    }
}

extension Plot where Self: HasGraphLayout {
    
    public func drawGraph(renderer: Renderer) {
        renderer.xOffset = xOffset
        renderer.yOffset = yOffset
        
        layout.legendLabels = self.legendLabels
        let results = layout.layout(renderer: renderer, calculateMarkers: { markers in
            calculateScaleAndMarkerLocations(markers: &markers, renderer: renderer)
        })
        layout.drawBackground(results: results, renderer: renderer)
        drawData(markers: results.plotMarkers, renderer: renderer)
        layout.drawForeground(results: results, renderer: renderer)
    }
    
}