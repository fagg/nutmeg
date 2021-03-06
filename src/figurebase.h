#ifndef FIGURE_H
#define FIGURE_H

#include <QQuickItem>
#include <QMultiMap>
#include "axisbase.h"
#include "controller.h"
#include "nutmegobject.h"
#include "mouseevent.h"

class AxisBase;
class Controller;
class FigureBase : public QQuickItem, public NutmegObject
{
    Q_OBJECT
    Q_PROPERTY(QString handle READ handle WRITE setHandle NOTIFY handleChanged)
    Q_PROPERTY(QVariantMap axes READ axes NOTIFY axesChanged)
    Q_PROPERTY(Controller* controller READ controller WRITE setController NOTIFY controllerChanged)
    Q_PROPERTY(int mouseButtons READ mouseButtons NOTIFY mouseButtonsChanged)
    Q_PROPERTY(QPointF mouse READ mouse NOTIFY mouseChanged)
    Q_PROPERTY(QPointF mouseUnit READ mouseUnit NOTIFY mouseUnitChanged)
public:
    explicit FigureBase(QQuickItem *parent = 0);
    ~FigureBase();

//    void paint(QPainter *painter);

    QVariantMap axes() const; // Use this for QML
    QList<AxisBase*> getAxesByHandle(const QString &handle) const; // Use this for c++
    Q_INVOKABLE QVariantList getAxisList();

    QString handle() const;
    void setHandle(QString arg);

    Controller* controller() const;
    void setController(Controller* arg);

    Q_INVOKABLE QString map(QString prop);

    Q_INVOKABLE void installEventFilterApp(QObject *app);
    bool eventFilter(QObject *watched, QEvent *event);

    QPointF mouse() const;
    void setMouse(QPointF arg);

    QPointF mouseUnit() const;
    void setMouseUnit(QPointF arg);

    int mouseButtons() const;
    void setMouseButtons(int arg);


signals:
    void mouseMoved(MouseEvent* mouse);
    void mousePressed(MouseEvent* mouse);
    void mouseReleased(MouseEvent* mouse);
    void axesChanged(QVariantMap arg);
    void handleChanged(QString arg);
    void addedAxis(AxisBase* axis);
    void controllerChanged(Controller* arg);
    void mouseChanged(QPointF arg);
    void mouseUnitChanged(QPointF arg);

    void mouseButtonsChanged(int arg);

public slots:
    void deregisterAxis(AxisBase *axis);
    void registerAxis(AxisBase *axis);

protected slots:
    void updateAxes();

private:
    QVariantMap m_axesVar;
    QVariantList m_axisList;
    QMultiMap<QString,AxisBase*> m_axes;
    bool m_destroying;

    QString m_handle;
    Controller* m_controller;
    QPointF m_mouse;
    QPointF m_mouseUnit;
    int m_mouseButtons;
};

#endif // FIGURE_H
