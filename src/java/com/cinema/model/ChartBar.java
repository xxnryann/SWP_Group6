package com.cinema.model;

/** Một cột/thanh của biểu đồ trên dashboard (percent = chiều cao/độ dài so với giá trị lớn nhất). */
public class ChartBar {
    private final String label;
    private final long value;
    private final int percent;

    public ChartBar(String label, long value, int percent) {
        this.label = label;
        this.value = value;
        this.percent = percent;
    }

    public String getLabel() { return label; }
    public long getValue() { return value; }
    public int getPercent() { return percent; }
}
