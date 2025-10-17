//
//  StatisticsView.swift
//  iTime
//
//  Created by Sean Zou on 2025/10/17.
//

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StatisticsViewModel?
    
    @State private var showingRecordList = false
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 时间段选择器
                            Picker("时间段", selection: Binding(
                                get: { viewModel.selectedPeriod },
                                set: { viewModel.changePeriod(to: $0) }
                            )) {
                                ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                                    Text(period.rawValue).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                    
                    // 日期导航
                    HStack {
                        Button {
                            viewModel.previousPeriod()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                        }
                        
                        Spacer()
                        
                        Text(viewModel.periodTitle)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            viewModel.nextPeriod()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 总计时长
                    VStack(spacing: 8) {
                        Text("总计")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.totalDuration.formattedDuration)
                            .font(.system(size: 36, weight: .bold))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    // 图表
                    if !viewModel.statistics.isEmpty {
                        ChartView(statistics: viewModel.statistics)
                            .frame(height: 250)
                            .padding()
                    }
                    
                    // 统计列表
                    if !viewModel.statistics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("分类统计")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.statistics) { stat in
                                StatisticRow(statistic: stat)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("暂无数据")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                    }
                    
                    // 查看详细记录按钮
                    if !viewModel.timeRecords.isEmpty {
                        Button {
                            showingRecordList = true
                        } label: {
                            HStack {
                                Text("查看详细记录")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle("统计")
                .sheet(isPresented: $showingRecordList) {
                    RecordListView(records: viewModel.timeRecords)
                }
            }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StatisticsViewModel(modelContext: modelContext)
            } else {
                viewModel?.loadData()
            }
        }
    }
}

// 统计行
struct StatisticRow: View {
    let statistic: EventStatistics
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // 颜色和名称
                Circle()
                    .fill(statistic.eventType.displayColor)
                    .frame(width: 12, height: 12)
                
                Text(statistic.eventType.name)
                    .font(.headline)
                
                Spacer()
                
                // 时长
                Text(statistic.totalDuration.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(statistic.eventType.displayColor)
                        .frame(width: geometry.size.width * statistic.percentage)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
            
            // 百分比和次数
            HStack {
                Text(String(format: "%.1f%%", statistic.percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(statistic.recordCount)次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(statistic.eventType.displayColor.opacity(0.05))
        )
        .padding(.horizontal)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [EventCategory.self, EventType.self, TimeRecord.self], inMemory: true)
}

