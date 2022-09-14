//
//  Property.swift
//  WFHCam
//
//  Created by Alessandro Loi on 11/09/22.
//

class Property {
    let getter: () -> PropertyValue
    let setter: ((UnsafeRawPointer) -> Void)?

    var isSettable: Bool {
        return setter != nil
    }

    var dataSize: UInt32 {
        getter().dataSize
    }

    convenience init<Element: PropertyValue>(_ value: Element) {
        self.init(getter: { value })
    }

    convenience init<Element: PropertyValue>(getter: @escaping () -> Element) {
        self.init(getter: getter, setter: nil)
    }

    init<Element: PropertyValue>(getter: @escaping () -> Element, setter: ((Element) -> Void)?) {
        self.getter = getter
        self.setter = (setter != nil) ? { data in setter?(Element.fromData(data: data)) } : nil
    }

    func getData(data: UnsafeMutableRawPointer) {
        let value = getter()
        value.toData(data: data)
    }

    func setData(data: UnsafeRawPointer) {
        setter?(data)
    }
}

