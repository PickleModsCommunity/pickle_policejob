import { SortAscIcon, SortDescIcon, TextIcon } from 'lucide-react';
import React, { useState, useMemo, useRef } from 'react';

interface Column<T> {
  key: keyof T;
  header: string;
  sortable?: boolean;
  width?: string;
}

interface TableProps<T> {
  data: T[];
  columns: Column<T>[];
  sortFunction?: (data: T[], sortKey: keyof T, sortDirection: 'asc' | 'desc') => T[];
  defaultSortKey?: keyof T;
  defaultSortDirection?: 'asc' | 'desc';
  maxHeight?: string;
}

function Table<T extends Record<string, any>>({
  data,
  columns,
  sortFunction,
  defaultSortKey,
  defaultSortDirection = 'asc',
  maxHeight = '400px'
}: TableProps<T>) {
  const [sortKey, setSortKey] = useState<keyof T | undefined>(defaultSortKey);
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>(defaultSortDirection);
  const tableRef = useRef<HTMLDivElement>(null);    
  const sortedData = useMemo(() => {
    if (!sortKey || !sortFunction) return data;
    return sortFunction(data, sortKey, sortDirection);
  }, [data, sortKey, sortDirection, sortFunction]);

  const handleSort = (columnKey: keyof T) => {
    if (sortKey === columnKey) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortKey(columnKey);
      setSortDirection('asc');
    }
    if (tableRef.current) {
      tableRef.current.scrollTop = 0;
    }
  };

  const getSortIcon = (columnKey: keyof T) => {
    if (sortKey !== columnKey) return <TextIcon className='w-4 h-4' />;
    return sortDirection === 'asc' ? <SortAscIcon className='w-4 h-4' /> : <SortDescIcon className='w-4 h-4' />;
  };

  return (
    <div ref={tableRef} style={{ maxHeight, overflow: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead className='bg-background select-none' style={{ position: 'sticky', top: 0 }}>
          <tr>
            {columns.map((column) => (
              <th
                key={String(column.key)}
                className='bg-secondary/50'
                style={{
                  padding: '12px',
                  textAlign: 'left',
                  cursor: column.sortable ? 'pointer' : 'default',
                  width: column.width || 'auto'
                }}
                onClick={() => column.sortable && handleSort(column.key)}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {column.header}
                  {column.sortable && (
                    <span style={{ fontSize: '12px' }}>
                      {getSortIcon(column.key)}
                    </span>
                  )}
                </div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {sortedData.map((row, index) => (
            <tr key={index} style={{ backgroundColor: index % 2 === 0 ? 'rgba(255, 255, 255, 0.1)' : 'rgba(255, 255, 255, 0.05)' }}>
              {columns.map((column) => (
                <td
                  key={String(column.key)}
                  style={{
                    padding: '12px',
                    width: column.width || 'auto'
                  }}
                >
                  {row[column.key]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default Table;
