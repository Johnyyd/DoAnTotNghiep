import { Toaster } from 'sonner';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from '@/components/Layout';
import Dashboard from '@/pages/Dashboard';
import Materials from '@/pages/Materials';
import Recipes from '@/pages/Recipes';
import ProductionOrders from '@/pages/ProductionOrders';
import ProductionBatches from '@/pages/ProductionBatches';
import Traceability from '@/pages/Traceability';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Layout />}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="materials" element={<Materials />} />
            <Route path="recipes" element={<Recipes />} />
            <Route path="production-orders" element={<ProductionOrders />} />
            <Route path="batches" element={<ProductionBatches />} />
            <Route path="traceability" element={<Traceability />} />
          </Route>
        </Routes>
      </BrowserRouter>
      <Toaster position="top-right" richColors />
    </QueryClientProvider>
  );
}

export default App;
