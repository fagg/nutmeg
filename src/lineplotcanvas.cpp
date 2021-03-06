#include "lineplotcanvas.h"
#include "lineplot.h"

LinePlotCanvas::LinePlotCanvas(QQuickItem *parent) :
    PlotCanvas(parent)
{
}

void LinePlotCanvas::paint(QPainter *painter)
{
    LinePlot *plot = qobject_cast<LinePlot*>(parent());
    if (!plot) return;

    AxisBase *monAxis = plot->axis();
    QList<qreal> xData = plot->xData(), yData = plot->yData();
    if (!monAxis || xData.length() != yData.length())
        return; // Funky data

//    qDebug() << "Plotting:" << plot->handle() << monAxis->dataLimits();
    QRectF dataLim = monAxis->dataLimits();
    // Need to frame the data based on the limits
    qreal minX = monAxis->minX();
    qreal minY = monAxis->minY();
    qreal maxX = monAxis->maxX();
    qreal maxY = monAxis->maxY();
//    qDebug() << "Init limits:" << "(" << minX << maxX << minY << maxY << ")";
    if (minX == -Inf) minX = dataLim.left();
    if (minY == -Inf) minY = dataLim.top();
    if (maxX == Inf) maxX = dataLim.right();
    if (maxY == Inf) maxY = dataLim.bottom();

    qreal scaleX = width()/(maxX - minX);
    qreal scaleY = height()/(maxY - minY);

//    qDebug() << "Size, scale:" << "(" << minX << maxX << minY << maxY << ")" << scaleX << scaleY;
    QPolygonF line;
    for (int i=0; i<yData.length(); ++i) {
        // Get it into workspace coords
        qreal px = xData[i];
        qreal py = yData[i];
        line << QPointF(scaleX*(px - minX), scaleY*(py - minY));
    }

    QRectF b = QRectF(0, 0, width(), height());
    QVector<QLineF> lines;
    for (int i=0; i<line.size() - 1; ++i) {
        QPointF p1 = line[i], p2 = line[i+1];
        QLineF l = rectSlice(p1, p2, b);
        if (!l.isNull())
            lines << l;
    }

//    qDebug() << "Defined poly:" << line.size();

    painter->setRenderHint(QPainter::Antialiasing);

    QPen pen = QPen();
    pen.setColor( plot->line()->color() );
    pen.setStyle( LineSpec::styleMap[plot->line()->style()] );
    pen.setWidthF( plot->line()->width() );

    painter->setPen(pen);
    painter->drawLines(lines);
//    qDebug() << "Done Plotting:" << plot->handle();
}

/*!
 * \brief LinePlotCanvas::rectSlice
 * Slice 2 points to a line contained by the rect, r
 * \param p1
 * \param p2
 * \param r
 * \return
 */
QLineF LinePlotCanvas::rectSlice(QPointF p1, QPointF p2, QRectF r)
{
    // https://gist.github.com/ChickenProp/3194723
    qreal minX = r.x();
    qreal minY = r.y();
    qreal maxX = minX + r.width();
    qreal maxY = minY + r.height();

    qreal dx = p2.x() - p1.x();
    qreal dy = p2.y() - p1.y();

    qreal v[4] = { -dx, dx, -dy, dy };
    qreal u[4] = { p1.x() - minX, maxX - p1.x(), p1.y() - minY, maxY - p1.y() };
    qreal t[4];


    qreal tMax = Inf, tMin = -Inf;
    for (int i=0; i<4; ++i) {
        if (v[i] != 0) {
            t[i] = u[i]/v[i];
            if (v[i] < 0 && tMin < t[i])
                tMin = t[i];
            if (v[i] > 0 && tMax > t[i])
                tMax = t[i];

        } else if (u[i] >= 0) {
            return QLineF(p1, p2); // Inside rect
        } else {
            return QLineF(); // Outside rect
        }
    }

    if (tMin >= tMax)
        return QLineF();

    if (tMax > 1) tMax = 1;
    if (tMax < 0) tMax = 0;
    if (tMin > 1) tMin = 1;
    if (tMin < 0) tMin = 0;

    QPointF q1(p1.x() + tMin*dx, p1.y() + tMin*dy);
    QPointF q2(p1.x() + tMax*dx, p1.y() + tMax*dy);

    return QLineF(q1, q2);
}

/**
 * @brief UtilEda::pointOnLine
 * @param point
 * @param l1 Defines the start of the line
 * @param l2 Defines the end of the line
 * @return Return 0 if the point is on the infinite line described by l1 and l2.
 * Return +ve if the point is "right" of the line - travelling from start to end.
 * Return -ve if the point is "left" of the line - travelling from start to end.
 */
qreal LinePlotCanvas::pointOnLine(QPointF point, QPointF l1, QPointF l2)
{
    return (l2.y() - l1.y())*point.x() + (l1.x() - l2.x())*point.y()
            + (l2.x()*l1.y() - l1.x()*l2.y());
}
